lex = require "./lexer"
parse = require "./parser"

#
tokens = lex """
  hello = (x, y) -> { x * x; };
  hello(10, 20);
  """

nodes = parse tokens

# console.log nodes

globalScope = {}
console.log node.evaluate(globalScope) for node in nodes