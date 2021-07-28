{ PointerType, FunctionType, stringToType } = require "./types"
Scope = require "./scope"
scope = new Scope

finalise = (nodes) -> finaliseNode node for node in nodes

finaliseNode = (node) ->
  switch node.type
    when "String", "Identifier", "Number"
      node.types = deriveType node
    when "Function"
      scope.changeScope()
      scope.saveVariable param, node.types.params[index] for param, index in node.params
      node.body = finalise node.body
      node.types = deriveType node
      scope.revertChanges()
    when "Call"
      node.args = finalise node.args
      node.types = deriveType node
    when "Array"
      item = finaliseNode item for item in node.items
      node.types = new PointerType node.items[0].types
    when "Binop"
      if node.operator is ":"
        scope.saveVariable node.LHS, node.RHS
      else
        node.LHS = finaliseNode node.LHS
        node.RHS = finaliseNode node.RHS
      if node.operator is "="
        if node.LHS.type is "Binop" then scope.saveVariable node.LHS.LHS, node.LHS.RHS
        else if node.LHS.type is "Array"
          scope.saveVariable item.name, node.RHS.types.base for item in node.LHS.items
        else if node.LHS.type isnt "Index" then scope.saveVariable node.LHS.name, node.RHS.types
      node.types = deriveType node
    when "Index"
      node.value = finaliseNode node.value
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
    when "Identifier" then scope.recallVariable node.name
    when "Array" then new PointerType node.items[0].types
    when "Function"
      if node.types.ret isnt null
        new FunctionType node.types.params, node.types.ret
      else
        returnType = null; index = 0
        while returnType is null and index < node.body.length
          if node.body[index].type is "Call" and node.body[index].callee is "return"
            returnType = node.body[index].types
            break
          index++
        new FunctionType node.types.params, returnType
    when "Call"
      if node.callee is "return"
        if node.args.length is 0 then stringToType "void"
        else node.args[0].types
      else
        (scope.recallVariable node.callee).ret
    when "Index" then node.types.base
    when "Binop"
      switch node.operator
        when "+", "-", "*", "<<", ">>", "|", "&", "^"
          LHStype = node.LHS.types; RHStype = node.RHS.types
          node.LHS.types
        when "/"
          LHStype = deriveType node.LHS; RHStype = deriveType node.RHS
          if LHStype.type is "Basic" and RHStype.type is "Basic"
            LHSbits = Number(LHStype.name[1..]); RHSbits = Number(LHStype.name[1..])
            signedness = if LHStype.name[0] is "i" or RHStype.name[0] is "i" then "i" else "u"
            stringToType signedness + Math.max LHSbits, RHSbits
        when "=" then deriveType node.RHS
        when "<", ">", "<=", ">=", "==", "!=", "&&", "||" then stringToType "bool"
        when ":" then node.RHS

module.exports = finalise
