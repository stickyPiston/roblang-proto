llvm = require "llvm-bindings"
Scope = require "./scope"

context = new llvm.LLVMContext()
mod = new llvm.Module "main", context
builder = new llvm.IRBuilder context

scope = new Scope

compile = (nodes) ->
  compileNode node for node in nodes
  unless llvm.verifyModule(mod)
    mod.print()
    llvm.WriteBitcodeToFile mod, "out.bc"
  else
    process.exit 1

compileAssignment = (node) ->
  # Firstly, compile the right-hand side
  switch node.RHS.type
    when "Function"
      returnType = getLLVMType node.RHS.types.ret
      type = llvm.FunctionType.get returnType, (node.RHS.types.params.map (t) -> getLLVMType t), false
      func = llvm.Function.Create type, llvm.Function.LinkageTypes.ExternalLinkage, (extractName node), mod
      block = llvm.BasicBlock.Create context, '', func
      builder.SetInsertionPoint block
      scope.changeScope()
      for param, index in node.RHS.params
        scope.saveVariable param, (new Variable (func.getArg index), "Parameter")
      compileNode bodyNode for bodyNode in node.RHS.body
      scope.revertChanges()
      res = new Variable func, "Function"
    when "String" then res = new Variable (compileNode node.RHS), "String"
    when "Array" then res = new Variable (compileNode node.RHS), "Array"
    when "Index" then res = new Variable (compileNode node.RHS), "Index"
    when "Identifier" then res = new Variable (compileNode node.RHS), "Identifier"
    when "Call" then res = new Variable (compileNode node.RHS), "Call"
    when "Number", "Binop" then res = new Variable (compileNode node.RHS), "Number"

  # Assign depending on the left-hand side
  switch node.LHS.type
    when "Index"
      ep = builder.CreateGEP (compileNode node.LHS.value), compileNode node.LHS.index
      if res.type in ["Number", "Call", "String", "Parameter"] then builder.CreateStore res.val, ep
      else builder.CreateStore (builder.CreateLoad res.val.getType().getElementType(), res.val), ep
    when "Array" # Array destructuring
      for item, index in node.LHS.items
        arr = compileNode node.RHS
        ep = builder.CreateGEP arr, llvm.ConstantInt.get builder.getInt8Ty(), index
        scope.saveVariable item.name, (new Variable ep, "Identifier")
    when "Identifier", "Binop"
      # FIXME: res.val = builder.CreatePointerCast res.val, getLLVMType node.LHS.RHS if node.RHS.types.base?.name is "any"
      if undefined is scope.recallVariable extractName node
        if res.type is "Function" or res.type is "String"
          scope.saveVariable (extractName node), res
        else
          alloca = builder.CreateAlloca (getLLVMType node.types), llvm.ConstantInt.get builder.getInt8Ty(), 1
          builder.CreateStore res.val, alloca
          scope.saveVariable (extractName node), new Variable alloca, res.type
      else
        alloca = (scope.recallVariable extractName node).val
        builder.CreateStore res.val, alloca
        # scope.saveVariable (extractName node), res

compileDeclaration = (node) ->
  returnType = getLLVMType node.RHS.ret
  type = llvm.FunctionType.get returnType, (node.RHS.params.map (t) -> getLLVMType t), false
  func = llvm.Function.Create type, llvm.Function.LinkageTypes.ExternalLinkage, node.LHS, mod
  scope.saveVariable node.LHS, (new Variable func, "Function")

compileBinop = (node) ->
  if node.LHS is null
    # Handle arity 1 operator
  else
    operands = {LHS: (compileNode node.LHS), RHS: (compileNode node.RHS)}
    switch node.operator
      when "+"
        builder.CreateIntCast (builder.CreateAdd operands.LHS, operands.RHS), (getLLVMType node.types), isSigned node.types
      when "-"
        builder.CreateIntCast (builder.CreateSub operands.LHS, operands.RHS), (getLLVMType node.types), isSigned node.types
      when "*"
        builder.CreateIntCast (builder.CreateMul operands.LHS, operands.RHS), (getLLVMType node.types), isSigned node.types
      when "/"
        if isSigned node.types then builder.CreateIntCast (builder.CreateSDiv operands.LHS, operands.RHS), (getLLVMType node.types), true
        else builder.CreateIntCast (builder.CreateUDiv operands.LHS, operands.RHS), (getLLVMType node.types), false
      when "<<"
        builder.CreateIntCast (builder.CreateShl operands.LHS, operands.RHS), (getLLVMType node.types), isSigned node.types
      when ">>"
        builder.CreateIntCast (builder.CreateLShr operands.LHS, operands.RHS), (getLLVMType node.types), isSigned node.types
      when "<"
        if isSigned node.types then builder.CreateIntCast (builder.CreateICmpSLT operands.LHS, operands.RHS), (getLLVMType node.types), true
        else builder.CreateIntCast (builder.CreateICmpULT operands.LHS, operands.RHS), (getLLVMType node.types), false
      when ">"
        if isSigned node.types then builder.CreateIntCast (builder.CreateICmpSGT operands.LHS, operands.RHS), (getLLVMType node.types), true
        else builder.CreateIntCast (builder.CreateICmpUGT operands.LHS, operands.RHS), (getLLVMType node.types), false
      when "=="
        builder.CreateIntCast (builder.CreateICmpEQ operands.LHS, operands.RHS), (getLLVMType node.types), isSigned node.types
      when "!="
        builder.CreateIntCast (builder.CreateICmpNE operands.LHS, operands.RHS), (getLLVMType node.types), isSigned node.types
      when ">="
        if isSigned node.types then builder.CreateIntCast (builder.CreateICmpSGE operands.LHS, operands.RHS), (getLLVMType node.types), true
        else builder.CreateIntCast (builder.CreateICmpUGE operands.LHS, operands.RHS), (getLLVMType node.types), false
      when "<="
        if isSigned node.types then builder.CreateIntCast (builder.CreateICmpSLE operands.LHS, operands.RHS), (getLLVMType node.types), true
        else builder.CreateIntCast (builder.CreateICmpULE operands.LHS, operands.RHS), (getLLVMType node.types), false
      when "&&", "||"
        lhscmp = builder.CreateICmpNE operands.LHS, llvm.ConstantInt.get (getLLVMType node.LHS.types), 0
        rhscmp = builder.CreateICmpNE operands.RHS, llvm.ConstantInt.get (getLLVMType node.RHS.types), 0
        if node.operator is "||" then builder.CreateIntCast (builder.CreateOr lhscmp, rhscmp), (getLLVMType node.types), isSigned node.types
        else builder.CreateIntCast (builder.CreateAnd lhscmp, rhscmp), (getLLVMType node.types), isSigned node.types
      when "&"
        builder.CreateIntCast (builder.CreateAnd operands.LHS, operands.RHS), (getLLVMType node.types), isSigned node.types
      when "|"
        builder.CreateIntCast (builder.CreateOr operands.LHS, operands.RHS), (getLLVMType node.types), isSigned node.types
      when "^"
        builder.CreateIntCast (builder.CreateXor operands.LHS, operands.RHS), (getLLVMType node.types), isSigned node.types

compileIndex = (node) ->
  if node.index.type is "Identifier"
    index = compileNode node.index
    builder.CreateGEP (compileNode node.value), builder.CreateIntCast (builder.CreateLoad index.getType().getElementType(), index), builder.getInt8Ty(), false
  else
    builder.CreateGEP (compileNode node.value), builder.CreateIntCast (compileNode node.index), builder.getInt8Ty(), false

compileArray = (node) ->
  alloca = builder.CreateAlloca (getLLVMType node.types.base), llvm.ConstantInt.get builder.getInt8Ty(), node.items.length
  for item, index in node.items
    ep = builder.CreateGEP alloca, (llvm.ConstantInt.get builder.getInt8Ty(), index)
    builder.CreateStore (compileNode item), ep
  alloca

compileIdentifier = (node) ->
  variable = scope.recallVariable node.name
  if variable.type in ["String", "Parameter"] then variable.val
  else builder.CreateLoad (getLLVMType node.types), (scope.recallVariable node.name).val

compileCall = (node) ->
  if node.callee is "return"
    if node.args.length is 0
      builder.CreateRetVoid()
    else
      arg = compileNode node.args[0]
      builder.CreateRet arg
  else
    args = []
    for arg in node.args
      compiledArg = compileNode arg
      args.push compiledArg
    builder.CreateCall (scope.recallVariable node.callee).val, args

compileNode = (node) ->
  switch node.type
    when "Binop"
      if node.operator is "=" then compileAssignment node
      else if node.operator is ":" then compileDeclaration node
      else compileBinop node
    when "Index" then compileIndex node
    when "Array" then compileArray node
    when "Number" then llvm.ConstantInt.get (getLLVMType node.types), node.value, isSigned node.types
    when "Identifier" then compileIdentifier node
    when "Call" then compileCall node
    when "String" then builder.CreateGlobalStringPtr node.value

# Arbitrary functions and stuff(TM)

class Variable
  constructor: (@val, @type) ->

extractName = (node) -> if node.LHS.type is "Binop" then node.LHS.LHS else node.LHS.name

BasicTypeMap =
  u8: builder.getInt8Ty(),   i8: builder.getInt8Ty(),
  u16: builder.getInt16Ty(), i16: builder.getInt16Ty(),
  u32: builder.getInt32Ty(), i32: builder.getInt32Ty(),
  u64: builder.getInt64Ty(), i64: builder.getInt64Ty(),
  "void": builder.getVoidTy(), any: builder.getInt8Ty()
  bool: builder.getInt1Ty()
getLLVMType = (t) ->
  if t.type is "Basic" then BasicTypeMap[t.name]
  else if t.type is "Pointer"
    llvm.PointerType.getUnqual getLLVMType t.base

isSigned = (t) -> t.type is "Basic" and t.name[0] is "i"

module.exports = compile
