llvm = require "llvm-bindings"

context = new llvm.LLVMContext()
mod = new llvm.Module "main", context
builder = new llvm.IRBuilder context
currentFunc = null
variables = {}

compile = (nodes) ->
  compileNode node for node in nodes
  unless llvm.verifyModule(mod)
    llvm.WriteBitcodeToFile mod, "out.bc"
  else
    process.exit 1

compileNode = (node) ->
  switch node.type
    when "Binop"
      switch node.operator
        when "="
          res = undefined
          if node.RHS.type is "Function"
            returnType = getLLVMType node.RHS.types.ret
            type = llvm.FunctionType.get returnType, (node.RHS.types.params.map (t) -> getLLVMType t), false
            func = llvm.Function.Create type, llvm.Function.LinkageTypes.ExternalLinkage, (extractName node), mod
            block = llvm.BasicBlock.Create context, '', func
            builder.SetInsertionPoint block
            currentfunc = func
            compileNode bodyNode for bodyNode in node.RHS.body
            currentfunc = null
            res = new Variable func, "Function"
          else if node.RHS.type is "String"
            variables[extractName node] = new Variable (compileNode node.RHS), "String"
          else if node.RHS.type is "Array"
            res = new Variable (compileNode node.RHS), "Array"
          else if node.RHS.type is "Index"
            res = new Variable (compileNode node.RHS), "Index"
          else
            if (extractName node) of variables
              builder.CreateStore (compileNode node.RHS), variables[extractName node].val
              res = variables[extractName node]
            else
              alloca = builder.CreateAlloca getLLVMType node.types
              builder.CreateStore (compileNode node.RHS), alloca
              res = new Variable alloca, "Regular"
          if node.LHS.type is "Index"
            ep = builder.CreateGEP (compileNode node.LHS.value), compileNode node.LHS.index
            builder.CreateStore (builder.CreateLoad res.val.getType().getElementType(), res.val), ep
          else
            variables[extractName node] = res
        else
          if node.LHS is null
          else
            operands = {LHS: (compileNode node.LHS), RHS: (compileNode node.RHS)}
            for operand of operands
              if node[operand].type is "Identifier" or node[operand].type is "Index"
                operands[operand] = builder.CreateLoad (getLLVMType node[operand].types), operands[operand]
            switch node.operator
              when "+"
                builder.CreateIntCast (builder.CreateAdd operands.LHS, operands.RHS), (getLLVMType node.types), isSigned node.types
              when "-"
                builder.CreateIntCast (builder.CreateSub operands.LHS, operands.RHS), (getLLVMType node.types), isSigned node.types
    when "Index"
      if node.index.type is "Identifier"
        index = compileNode node.index
        builder.CreateGEP (compileNode node.value), builder.CreateLoad index.getType().getElementType(), index
      else
        builder.CreateGEP (compileNode node.value), compileNode node.index
    when "Array"
      alloca = builder.CreateAlloca (getLLVMType node.types.base), llvm.ConstantInt.get builder.getInt8Ty(), node.items.length
      for item, index in node.items
        ep = builder.CreateGEP alloca, (llvm.ConstantInt.get builder.getInt8Ty(), index)
        builder.CreateStore (compileNode item), ep
      alloca
    when "Number"
      llvm.ConstantInt.get (getLLVMType node.types), node.value, true
    when "Identifier"
      if variables[node.name].type is "Regular"
        # builder.CreateLoad variables[node.name].val.getType().getElementType(), variables[node.name].val
        variables[node.name].val
      else
        variables[node.name].val
    when "Call"
      if node.callee is "return"
        if node.args.length is 0
          builder.CreateRetVoid()
        else
          arg = compileNode node.args[0]
          builder.CreateRet builder.CreateLoad arg.getType().getElementType(), arg
      else if node.callee is "puts"
        type = llvm.FunctionType.get builder.getInt32Ty(), [builder.getInt8PtrTy()], false
        puts = llvm.Function.Create type, llvm.Function.LinkageTypes.ExternalLinkage, "puts", mod
        builder.CreateCall puts, (compileNode arg for arg in node.args)
      else
        args = []
        for arg in node.args
          compiledArg = compileNode arg
          args.push builder.CreateLoad compiledArg.getType().getElementType(), compiledArg
        builder.CreateCall variables[node.callee], args
    when "String"
      builder.CreateGlobalStringPtr node.value

# Arbitrary functions and stuff(TM)

class Variable
  constructor: (@val, @type) ->

extractName = (node) -> if node.LHS.type is "Binop" then node.LHS.LHS else node.LHS.name

BasicTypeMap =
  u8: builder.getInt8Ty(),   i8: builder.getInt8Ty(),
  u16: builder.getInt16Ty(), i16: builder.getInt16Ty(),
  u32: builder.getInt32Ty(), i32: builder.getInt32Ty(),
  u64: builder.getInt64Ty(), i64: builder.getInt64Ty(),
  "void": builder.getVoidTy()
getLLVMType = (t) ->
  if t.type is "Basic" then BasicTypeMap[t.name]

isSigned = (t) -> t.type is "Basic" and t.name[0] is "i"

module.exports = compile
