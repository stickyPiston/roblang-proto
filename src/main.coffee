lex = require "./lexer"
parse = require "./parser"
{ ScopeManager, Scope } = require "./scope"

#  greet = () -> { print("Hello, world!"); };
#  greet();
tokens = lex """
  min = (x, y) -> {
    return(
      if(x < y, () -> {
        return(x);
      }, () -> {
        return(y);
      })
    );
  };

  print(min(20, 30));
  """

nodes = parse tokens

# console.log nodes

globalScope = ScopeManager.add new Scope
node.evaluate(globalScope) for node in nodes