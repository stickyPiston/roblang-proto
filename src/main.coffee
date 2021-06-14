lex = require "./lexer"
parse = require "./parser"

#  greet = () -> { print("Hello, world!"); };
#  greet();
tokens = lex """
  isSmaller = (x, y) -> {
    return(
      if(x < y, () -> {
        return(1);
      }, () -> {
        return(0);
      })
    );
  };

  print(isSmaller(20, 30));
  """

nodes = parse tokens

# console.log nodes

globalScope = {}
node.evaluate(globalScope) for node in nodes