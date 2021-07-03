{ PointerType, FunctionType, stringToType } = require "./types"
scope = {
  putd: new FunctionType [stringToType "i64"], stringToType "i32"
  puts: new FunctionType [new PointerType stringToType "u8"], stringToType "i32"
}; currentScope = ""
check = (nodes) -> checkNode node for node in nodes
checkNode = (node) ->
  if node.type is "Call"
    # Check if params match up
    func = getFromScope node.callee
    if node.callee is "return"
      # In the future: check compliance with function return type
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
        else writeToScope node.LHS.LHS, node.LHS.RHS
      else writeToScope node.LHS.name, node.RHS.types
    else
      check [node.LHS, node.RHS]
      unless ((isNumber node.LHS.types) and (isNumber node.RHS.types)) # not canAssignTo node.LHS.types, node.RHS.types
        console.error "No available operator #{node.LHS.types.name} #{node.operator} #{node.RHS.types.name}"
        process.exit 1
  else if node.type is "Function" then check node.body

canAssignTo = (type_a, type_b) ->
  if type_a.type is "Basic" and type_b.type is "Basic"
    a = type_a.name; b = type_b.name
    if a is "u16" and b is "u8" then return true
    else if a is "u32" and b in ["u8", "u16"] then return true
    else if a is "u64" and b in ["u8", "u16", "u32"] then return true
    else if a is "i16" and b in ["i8", "u8"] then return true
    else if a is "i32" and b in ["i8", "u8", "i16", "u16"] then return true
    else if a is "i64" and b in ["i8", "u8", "i16", "u16", "u32", "i32"] then return true
    else if a is b then return true
    return false
  else if type_b is "Function"
    return canAssignTo type_a, type_b.ret
  else if type_a.type is "Pointer" is type_b.type is "Pointer"
    return canAssignTo type_a.base, type_b.base

isNumber = (type) -> type.type is "Basic"

# @type {(name: string) => Type}
getFromScope = (name) ->
  if currentScope is "" then scope[name]
  else scope[currentScope][name] # For now assuming that function won't be put in functions

writeToScope = (name, value) ->
  if currentScope is "" then scope[name] = value
  else scope[currentScope][name] = value

module.exports = check
