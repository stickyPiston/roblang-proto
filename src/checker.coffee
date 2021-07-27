{ PointerType, FunctionType, stringToType } = require "./types"
Scope = require "./scope"
scope = new Scope

check = (nodes) -> checkNode node for node in nodes
checkNode = (node) ->
  console.log node, scope
  if node.type is "Call"
    # Check if params match up
    func = scope.recallVariable node.callee
    if node.callee is "return"
      # TODO: In the future: check compliance with function return type
      if node.args.length > 1
        console.error "Wrong number of arguments to return call"
        process.exit 1
      if node.args.length is 1
        checkNode node.args[0]
      return
    for arg, index in node.args
      checkNode arg
      unless canAssignTo func.params[index], arg.types
        console.error arg.types, func.params[index]
        console.error "Type mismatch, cannot assign #{arg.types.name} to #{func.params[index].name}"
        process.exit 1
  else if node.type is "Binop"
    # Check if LHS and RHS make for a good combo
    if node.operator is "="
      checkNode node.RHS
      if node.LHS.type is "Binop"
        unless canAssignTo node.LHS.RHS, node.RHS.types
          console.error "Type mismatch, cannot assign #{node.RHS.types.name} to #{node.LHS.RHS.name} in assignment"
          process.exit 1
        else scope.saveVariable node.LHS.LHS, node.LHS.RHS
      else if node.LHS.type is "Array"
        scope.saveVariable item.name, node.RHS.types.base for item in node.LHS.items
      else scope.saveVariable node.LHS.name, node.RHS.types
    else if node.operator isnt ":"
      check [node.LHS, node.RHS]
      unless ((isNumber node.LHS.types) and (isNumber node.RHS.types))
        console.error "No available operator #{node.LHS.types.name} #{node.operator} #{node.RHS.types.name}"
        process.exit 1
    else scope.saveVariable node.LHS, node.types
  else if node.type is "Function"
    scope.changeScope()
    check node.body
    scope.revertChanges()

canAssignTo = (type_a, type_b) ->
  if type_a.type is "Basic" and type_b.type is "Basic"
    a = type_a.name; b = type_b.name
    if a is "u8" and b is "bool" then return true
    else if a is "u16" and b in ["bool", "u8"] then return true
    else if a is "u32" and b in ["bool", "u8", "u16"] then return true
    else if a is "u64" and b in ["bool", "u8", "u16", "u32"] then return true
    else if a is "i8" and b is "bool" then return true
    else if a is "i16" and b in ["bool", "i8", "u8"] then return true
    else if a is "i32" and b in ["bool", "i8", "u8", "i16", "u16"] then return true
    else if a is "i64" and b in ["bool", "i8", "u8", "i16", "u16", "u32", "i32"] then return true
    else if a is b then return true
    else if a is "any" or b is "any" then return true
    return false
  else if type_b is "Function"
    return canAssignTo type_a, type_b.ret
  else if type_a.type is "Pointer" is type_b.type is "Pointer"
    return canAssignTo type_a.base, type_b.base

isNumber = (type) -> type.type is "Basic"

module.exports = check
