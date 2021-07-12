llvm = require "llvm-bindings"

context = new llvm.LLVMContext()
mod = new llvm.Module "main", context
builder = new llvm.IRBuilder context
currentFunc = null
variables = {}

compile = (nodes) ->
  compileNode node for node in nodes
  unless llvm.verifyModule(mod)
    mod.print()
    llvm.WriteBitcodeToFile mod, "out.bc"
  else
    process.exit 1

compileNode = (node) ->
  # console.log node
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
            res = new Variable (compileNode node.RHS), "String"
          else if node.RHS.type is "Array"
            res = new Variable (compileNode node.RHS), "Array"
          else if node.RHS.type is "Index"
            res = new Variable (compileNode node.RHS), "Index"
          else if node.RHS.type is "Identifier"
            res = variables[node.RHS.name]
          else if node.RHS.type is "Call"
            if node.RHS.types.type is "Pointer"
              res = new Variable (compileNode node.RHS), "Call"
            else
              res = new Variable (builder.CreateLoad (getLLVMType node.RHS.types), compileNode node.RHS), "Call"
          else
            if (extractName node) of variables
              builder.CreateStore (compileNode node.RHS), variables[extractName node].val
              res = variables[extractName node]
            else
              alloca = builder.CreateAlloca getLLVMType node.types
              builder.CreateStore (compileNode node.RHS), alloca
              res = new Variable alloca, "Regular"
          if node.LHS.type is "Index"
            ep = builder.CreateGEP (compileNode node.LHS.value), loadVar (compileNode node.LHS.index), node.LHS.index
            builder.CreateStore (builder.CreateLoad res.val.getType().getElementType(), res.val), ep
          else if node.LHS.type is "Array"
            for item, index in node.LHS.items
              arr = compileNode node.RHS
              ep = builder.CreateGEP arr, llvm.ConstantInt.get builder.getInt8Ty(), index
              variables[item.name] = new Variable ep, "Regular"
          else
            res.val = builder.CreatePointerCast res.val, getLLVMType node.LHS.RHS if node.RHS.types.base?.name is "any"
            variables[extractName node] = res
        when ":"
          returnType = getLLVMType node.RHS.ret
          type = llvm.FunctionType.get returnType, (node.RHS.params.map (t) -> getLLVMType t), false
          func = llvm.Function.Create type, llvm.Function.LinkageTypes.ExternalLinkage, node.LHS, mod
          variables[node.LHS] = new Variable func, "Function"
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
        console.log node, index
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
        variables[node.name].val
      else
        variables[node.name].val
    when "Call"
      if node.callee is "return"
        if node.args.length is 0
          builder.CreateRetVoid()
        else
          arg = compileNode node.args[0]
          builder.CreateRet arg
      else
        args = []
        for arg in node.args
          compiledArg = loadVar (compileNode arg), arg.type
          args.push compiledArg
        builder.CreateCall variables[node.callee].val, args
    when "String"
      builder.CreateGlobalStringPtr node.value

# Arbitrary functions and stuff(TM)

class Variable
  constructor: (@val, @type) ->

loadVar = (v, type) ->
  if type.type is "Identifier" and type.types.type isnt "pointer" then builder.CreateLoad v.getType().getElementType(), v
  else v

extractName = (node) -> if node.LHS.type is "Binop" then node.LHS.LHS else node.LHS.name

BasicTypeMap =
  u8: builder.getInt8Ty(),   i8: builder.getInt8Ty(),
  u16: builder.getInt16Ty(), i16: builder.getInt16Ty(),
  u32: builder.getInt32Ty(), i32: builder.getInt32Ty(),
  u64: builder.getInt64Ty(), i64: builder.getInt64Ty(),
  "void": builder.getVoidTy(), any: builder.getInt8Ty()
getLLVMType = (t) ->
  if t.type is "Basic" then BasicTypeMap[t.name]
  else if t.type is "Pointer"
    llvm.PointerType.getUnqual getLLVMType t.base #BasicTypeMap[t.base.name]

isSigned = (t) -> t.type is "Basic" and t.name[0] is "i"

module.exports = compile
