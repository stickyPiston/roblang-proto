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

class IndexNode extends Node
  constructor: (@value, @index) ->
    super()
    @type = "Index"

class ArrayNode extends Node
  constructor: (@items) ->
    super()
    @type = "Array"

module.exports = {
  Node,
  BinopNode,
  IdentifierNode,
  NumberNode,
  CallNode,
  FunctionNode,
  StringLiteralNode,
  IndexNode,
  ArrayNode
}
