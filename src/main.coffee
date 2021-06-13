lex = require "./lexer"
parse = require "./parser"

tokens = lex """
  hello = (x, y) -> { x * x; };
  """

nodes = parse tokens

console.log nodes

# console.log node.evaluate() for node in nodes