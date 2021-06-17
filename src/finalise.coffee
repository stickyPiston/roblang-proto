{ PointerType, FunctionType, stringToType } = require "./checker"

scope = {
  puts: new FunctionType [stringToType "i32"], stringToType "i32"
}; currentScope = ""
finalise = (nodes) -> finaliseNode node for node in nodes

finaliseNode = (node) ->
  # console.log "Finalising", node
  switch node.type
    when "String", "Identifier", "Number"
      node.types = deriveType node
    when "Function"
      writeToScope param.name, param.types for param in node.params
      # console.log param for param in node.params
      node.body = finalise node.body
      node.types = deriveType node
      # console.log node
    when "Call"
      node.args = finalise node.args
      # console.log node.args
      node.types = deriveType node
    when "Binop"
      node.LHS = finaliseNode node.LHS
      node.RHS = finaliseNode node.RHS
      if node.operator is "="
        if node.LHS.type is "Binop" then writeToScope node.LHS.LHS, node.LHS.RHS
        else writeToScope node.LHS.name, deriveType node.RHS
        # console.log "Writing #{node.LHS} to ", scope
      node.types = deriveType node
  node

# @type {(node: Node) => Type}
deriveType = (node) ->
  switch node.type
    when "Number"
      if node.value > 0
        if node.value < 256 then stringToType "u8"
        else if node.value < 65536 then stringToType "u16"
        else if node.value < 4294967296 then stringToType "u32"
        else if node.value < 1.844674407370955e19 then stringToType "u64"
      else
        if node.value >= -128 then stringToType "i8"
        else if node.value >= -32768 then stringToType "i16"
        else if node.value >= -2147483648 then stringToType "i32"
        else if node.value >= -9.223372036854776e18 then stringToType "i64"
    when "String" then new PointerType stringToType "u8"
    when "Identifier" then getFromScope node.name
    when "Function" then new FunctionType node.types.params, node.types.ret
    when "Call" 
      if node.callee is "return" then node.args[0].types
      else
        # console.log node.callee, scope
        (getFromScope node.callee).ret
    when "Binop"
      # console.log node
      switch node.operator
        when "+", "-", "*"
          LHStype = deriveType node.LHS; RHStype = deriveType node.RHS
          if LHStype.type is "Basic" and RHStype.type is "Basic"
            LHSbits = Number(LHStype.name[1..]); RHSbits = Number(LHStype.name[1..]);
            nextBasicType = (start) ->
              bits = [8, 16, 32, 64, 0]
              Math.max 64, bits[(bits.findIndex (e) -> e is start) + 1]
            signedness = if LHStype.name[0] is "i" or RHStype.name[0] is "i" then "i" else "u"
            if LHSbits < RHSbits then signedness + nextBasicType RHSbits
            else signedness + nextBasicType LHSbits
        when "/"
          LHStype = deriveType node.LHS; RHStype = deriveType node.RHS
          if LHStype.type is "Basic" and RHStype.type is "Basic"
            LHSbits = Number(LHStype.name[1..]); RHSbits = Number(LHStype.name[1..]);
            signedness = if LHStype.name[0] is "i" or RHStype.name[0] is "i" then "i" else "u"
            stringToType signedness + Math.max LHSbits, RHSbits
        when "="
          deriveType node.RHS
        when "<", ">"
          stringToType "u8"

# @type {(name: string) => Type}
getFromScope = (name) ->
  if currentScope is "" then scope[name]
  else scope[currentScope][name] # For now assuming that function won't be put in functions

writeToScope = (name, value) ->
  if currentScope is "" then scope[name] = value
  else scope[currentScope][name] = value

module.exports = finalise