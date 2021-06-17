{ intrinsics, mustReturn, resetReturn } = require "./intrinsics"
{ ScopeManager, Scope } = require "./scope"

class Node
  constructor: ->
    @type = "None"
    @types = {}

class BinopNode extends Node
  constructor: (@operator, @LHS, @RHS) ->
    super()
    @type = "Binop"
  
  evaluate: (scope) ->
    if @operator isnt "="
      lval = @LHS.evaluate(scope)
      rval = @RHS.evaluate(scope)
      switch
        when @operator is "+" then lval + rval
        when @operator is "-" then lval - rval
        when @operator is "*" then lval * rval
        when @operator is "/" then lval / rval
        when @operator is "<" then lval < rval
        when @operator is ">" then lval > rval
        when @operator is "<=" then lval <= rval
        when @operator is ">=" then lval >= rval
    else
      ScopeManager.set scope, @LHS.name, @RHS.evaluate(scope)

class IdentifierNode extends Node
  constructor: (@name) ->
    super()
    @type = "Identifier"
  
  evaluate: (scope) ->
    ScopeManager.recall scope, @name

class NumberNode extends Node
  constructor: (@value) ->
    super()
    @type = "Number"
  
  evaluate: (_) -> @value

class CallNode extends Node
  constructor: (@callee, @args) ->
    super()
    @type = "Call"
  
  evaluate: (scope) ->
    if @callee of intrinsics
      intrinsics[@callee](scope, @args)
    else
      if (ScopeManager.recall scope, @callee).body is undefined then return
      newScope = ScopeManager.add new Scope scope
      (ScopeManager.set newScope, param.name, @args[i].evaluate scope) for param, i in (ScopeManager.recall scope, @callee).params
      for N in (ScopeManager.recall scope, @callee).body
        N.evaluate(newScope)
        if mustReturn() isnt false
          returnValue = mustReturn()
          resetReturn()
          return returnValue

class FunctionNode extends Node
  constructor: (@params, @body) ->
    super()
    @type = "Function"

  evaluate: (_) -> this

class StringLiteralNode extends Node
  constructor: (@value) ->
    super()
    @type = "String"
  
  evaluate: (_) -> @value

module.exports =
  Node: Node
  BinopNode: BinopNode
  IdentifierNode: IdentifierNode
  NumberNode: NumberNode
  CallNode: CallNode
  FunctionNode: FunctionNode
  StringLiteralNode: StringLiteralNode