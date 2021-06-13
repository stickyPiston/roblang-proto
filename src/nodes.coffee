class Node
  constructor: () -> type = "None"

variables = {}

class BinopNode extends Node
  constructor: (@operator, @LHS, @RHS) ->
    super()
    type = "Binop"
  
  evaluate: () ->
    lval = @LHS.evaluate()
    rval = @RHS.evaluate()
    switch
      when @operator is "+" then lval + rval
      when @operator is "-" then lval - rval
      when @operator is "*" then lval * rval
      when @operator is "/" then lval / rval
      when @operator is "=" then variables[@LHS.name] = rval

class IdentifierNode extends Node
  constructor: (@name) ->
    super()
    type = "Identifier"
  
  evaluate: () -> variables[@name]

class NumberNode extends Node
  constructor: (@value) ->
    super()
    type = "Number"
  
  evaluate: () -> @value

class CallNode extends Node
  constructor: (@callee, @args) ->
    super()
    type = "Call"

class FunctionNode extends Node
  constructor: (@params, @body) ->
    super()
    type = "Function"

module.exports =
  Node: Node
  BinopNode: BinopNode
  IdentifierNode: IdentifierNode
  NumberNode: NumberNode
  CallNode: CallNode
  FunctionNode: FunctionNode