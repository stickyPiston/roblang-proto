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
          if node.RHS.type is "Function"
            returnType = getLLVMType node.RHS.types.ret
            type = llvm.FunctionType.get returnType, (node.RHS.types.params.map (t) -> getLLVMType t), false
            func = llvm.Function.Create type, llvm.Function.LinkageTypes.ExternalLinkage, (extractName node), mod
            block = llvm.BasicBlock.Create context, '', func
            builder.SetInsertionPoint block
            currentfunc = func
            compileNode bodyNode for bodyNode in node.RHS.body
            currentfunc = null
            variables[extractName node] = new Variable func, "Function"
          else if node.RHS.type is "String"
            variables[extractName node] = new Variable (compileNode node.RHS), "String"
          else if node.RHS.type is "Array"
            variables[extractName node] = new Variable (compileNode node.RHS), "Array"
          else if node.RHS.type is "Index"
            variables[extractName node] = new Variable (compileNode node.RHS), "Index"
            # console.log variables[extractName node]
          else
            alloca = builder.CreateAlloca getLLVMType node.types
            store = builder.CreateStore (compileNode node.RHS), alloca
            variables[extractName node] = new Variable alloca, "Regular"
        when "+" then builder.CreateIntCast (builder.CreateAdd (compileNode node.LHS), (compileNode node.RHS)), (getLLVMType node.types), isSigned node.types
        when "-" then builder.CreateIntCast (builder.CreateSub (compileNode node.LHS), (compileNode node.RHS)), (getLLVMType node.types), isSigned node.types
    when "Index"
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
        builder.CreateLoad variables[node.name].val.getType().getElementType(), variables[node.name].val
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
