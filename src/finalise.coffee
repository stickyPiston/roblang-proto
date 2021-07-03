{ PointerType, FunctionType, stringToType } = require "./types"

scope = {
  puts: new FunctionType [new PointerType stringToType "u8"], stringToType "i32"
}; currentScope = ""; currentFunc = null
finalise = (nodes) -> finaliseNode node for node in nodes

finaliseNode = (node) ->
  # console.log "Finalising", node
  switch node.type
    when "String", "Identifier", "Number"
      node.types = deriveType node
    when "Function"
      writeToScope param, node.types.params[index] for param, index in node.params
      currentFunc = node.types
      node.body = finalise node.body
      node.types = deriveType node
      currentFunc = null
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
    when "Index"
      baseType = deriveType node.value
      if baseType.type isnt "Pointer"
        console.error "Dereferencing a non-pointer variable"
        process.exit 1
      else
        node.types = baseType.base
        node.index = finaliseNode node.index
    when "Number"
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
    when "Function"
      if node.types.ret isnt null
        new FunctionType node.types.params, node.types.ret
      else
        returnType = null; index = 0
        console.log "Determining return type", node.body
        while returnType is null and index < node.body.length
          if node.body[index].type is "Call" and node.body[index].callee is "return"
            returnType = node.body[index].types
            break
          console.log returnType
          index++
        new FunctionType node.types.params, returnType
    when "Call"
      if node.callee is "return"
        if node.args.length is 0 then stringToType "void"
        else node.args[0].types
      else
        # console.log node.callee, scope
        (getFromScope node.callee).ret
    when "Index" then node.types.base
    when "Binop"
      switch node.operator
        when "+", "-", "*"
          LHStype = node.LHS.types; RHStype = node.RHS.types
          if LHStype.type is "Basic" and RHStype.type is "Basic"
            LHSbits = Number(LHStype.name[1..]); RHSbits = Number(LHStype.name[1..])
            nextBasicType = (start) ->
              bits = [8, 16, 32, 64, 128]
              Math.min 64, bits[(bits.findIndex (e) -> e is start) + 1]
            signedness = if LHStype.name[0] is "i" or RHStype.name[0] is "i" then "i" else "u"
            if LHSbits < RHSbits then stringToType signedness + nextBasicType RHSbits
            else stringToType signedness + nextBasicType LHSbits
        when "/"
          LHStype = deriveType node.LHS; RHStype = deriveType node.RHS
          if LHStype.type is "Basic" and RHStype.type is "Basic"
            LHSbits = Number(LHStype.name[1..]); RHSbits = Number(LHStype.name[1..])
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
