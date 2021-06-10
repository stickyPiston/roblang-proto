{ IdentifierNode, CallNode, BinopNode, NumberNode } = require "./nodes"

operators = [
  "=", "+=", "-=", "/=", "*=", "||=", "&&=", "<<=", ">>=", "&=",
  "|=", "^=", "&&", "||", "^^", "<", ">", "<=", ">=", "==", "!=",
  "+", "-", "&", "|", "^", "*", "/", "<<", ">>", "!", "~"
]

parse = (tokens) ->
  N = []
  loop
    E = parseExpression tokens
    
    endIndex = tokens.findIndex (e) -> e.value is ";"
    if endIndex isnt -1 then tokens = tokens[endIndex+1..]
    else break

    if E then N.push E
    else break
  N

parseExpression = (tokens) ->
  hasOperator = false
  if tokens.length is 0
    return null
  else if tokens.length isnt 1
    level = 0
    for token in tokens
      if token.value in ["(", "[", "{"] then level++
      if token.value in [")", "]", "}"] then level--
      hasOperator = hasOperator || token.value in operators
  
  if hasOperator or tokens.length > 1
    for operator in operators
      for token, index in tokens
        if token.value is operator
          LHStokens = tokens[..index-1]
          endIndex = tokens.findIndex (e) -> e.value is ";"
          endIndex = if endIndex is -1 then tokens.length else endIndex
          RHStokens = tokens[index+1..endIndex-1]
          return new BinopNode operator, parseExpression(LHStokens), parseExpression(RHStokens)
  else
    return parsePrimary tokens

parseIdentifierExpression = (tokens) ->
  if tokens.length is 1
    new IdentifierNode tokens[0].value
  else if tokens[1].value is "("
    new CallNode tokens[0].value, ""

parseNumber = (tokens) -> new NumberNode(Number(tokens[0].value))

parsePrimary = (tokens) ->
  switch
    when tokens[0].type is "Identifier" then parseIdentifierExpression tokens
    when tokens[0].type is "Number" then parseNumber tokens
    when tokens[0].value is "(" then parseExpression tokens[1..]

module.exports = parse