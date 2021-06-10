lex = require "./lexer"
parse = require "./parser"

tokens = lex """
  hello = 1 + 10 * 2;
  2 * hello;
  """

nodes = parse tokens

console.log node.evaluate() for node in nodes