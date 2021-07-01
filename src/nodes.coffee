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

class IdentifierNode extends Node
  constructor: (@name) ->
    super()
    @type = "Identifier"

class NumberNode extends Node
  constructor: (@value) ->
    super()
    @type = "Number"

class CallNode extends Node
  constructor: (@callee, @args) ->
    super()
    @type = "Call"

class FunctionNode extends Node
  constructor: (@params, @body) ->
    super()
    @type = "Function"

class StringLiteralNode extends Node
  constructor: (@value) ->
    super()
    @type = "String"

module.exports =
  Node: Node
  BinopNode: BinopNode
  IdentifierNode: IdentifierNode
  NumberNode: NumberNode
  CallNode: CallNode
  FunctionNode: FunctionNode
  StringLiteralNode: StringLiteralNode