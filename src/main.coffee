lex = require "./lexer"
parse = require "./parser"

tokens = lex """
  mul = (x, y) -> { return(x * y); print(10); };
  print(mul(10, 30));
  """

nodes = parse tokens

globalScope = {}
node.evaluate(globalScope) for node in nodes