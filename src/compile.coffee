llvm = require "llvm-bindings"

context = new llvm.LLVMContext()
mod = new llvm.Module "main", context
builder = new llvm.IRBuilder context
### mainfunc = llvm.Function.Create llvm.FunctionType.get(builder.getInt32Ty(), [], false),
  llvm.Function.LinkageTypes.ExternalLinkage,
  'main',
  mod
mainblock = llvm.BasicBlock.Create context, 'entry', mainfunc
builder.SetInsertionPoint mainblock ###

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
            variables[extractName node] = func
          else
            alloca = builder.CreateAlloca getLLVMType node.types
            store = builder.CreateStore (compileNode node.RHS), alloca
            variables[extractName node] = alloca
        when "+" then builder.CreateIntCast (builder.CreateAdd (compileNode node.LHS), (compileNode node.RHS)), (getLLVMType node.types), isSigned node.types
        when "-" then builder.CreateIntCast (builder.CreateSub (compileNode node.LHS), (compileNode node.RHS)), (getLLVMType node.types), isSigned node.types
    when "Number"
      llvm.ConstantInt.get (getLLVMType node.types), node.value, true
    when "Identifier"
      builder.CreateLoad variables[node.name].getType().getElementType(), variables[node.name]
    when "Call"
      if node.callee is "return"
        if node.args.length is 0
          builder.CreateRetVoid()
        else
          builder.CreateRet compileNode node.args[0]
      else
        builder.CreateCall variables[node.callee], (compileNode arg for arg in node.args)

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
