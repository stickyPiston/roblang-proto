{ intrinsics, mustReturn, resetReturn } = require "./intrinsics"

class Node
  constructor: -> type = "None"

class BinopNode extends Node
  constructor: (@operator, @LHS, @RHS) ->
    super()
    type = "Binop"
  
  evaluate: (scope) ->
    lval = @LHS.evaluate(scope)
    rval = @RHS.evaluate(scope)
    switch
      when @operator is "+" then lval + rval
      when @operator is "-" then lval - rval
      when @operator is "*" then lval * rval
      when @operator is "/" then lval / rval
      when @operator is "=" then scope[@LHS.name] = rval

class IdentifierNode extends Node
  constructor: (@name) ->
    super()
    type = "Identifier"
  
  evaluate: (scope) -> scope[@name]

class NumberNode extends Node
  constructor: (@value) ->
    super()
    type = "Number"
  
  evaluate: (_) -> @value

class CallNode extends Node
  constructor: (@callee, @args) ->
    super()
    type = "Call"
  
  evaluate: (scope) ->
    if @callee of intrinsics
      intrinsics[@callee](scope, @args)
    else
      currentFunction = scope[@callee]
      newScope = {}
      newScope[param.name] = @args[i].evaluate scope for param, i in scope[@callee].params
      for N in scope[@callee].body
        N.evaluate(newScope)
        if mustReturn() isnt false
          returnValue = mustReturn()
          resetReturn()
          return returnValue

class FunctionNode extends Node
  constructor: (@params, @body) ->
    super()
    type = "Function"

  evaluate: (_) -> this

module.exports =
  Node: Node
  BinopNode: BinopNode
  IdentifierNode: IdentifierNode
  NumberNode: NumberNode
  CallNode: CallNode
  FunctionNode: FunctionNode