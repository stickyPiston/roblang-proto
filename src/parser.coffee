{ IdentifierNode, CallNode, BinopNode, NumberNode, FunctionNode } = require "./nodes"

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
    if endIndex isnt -1 then tokens = tokens[endIndex+1..] else break
    if E then N.push E else break
  N

parseExpression = (tokens, delims = [";"]) ->
  hasOperator = false
  if tokens.length is 0
    return null
  else if tokens.length isnt 1
    level = 0
    for token in tokens
      if token.value in ["(", "[", "{"] then level++
      if token.value in [")", "]", "}"] then level--
      hasOperator = hasOperator or (token.value in operators and level is 0)

  if hasOperator
    for operator in operators
      level = 0
      for token, index in tokens
        if token.value in ["(", "[", "{"] then level++
        else if token.value in [")", "]", "}"] then level--
        else if token.value is operator and level is 0
          LHStokens = tokens[..index-1]
          for t, i in tokens[index..]
            if t.value in ["(", "[", "{"] then level++
            else if t.value in [")", "]", "}"] then level--
            else if t.value in delims then endIndex = index + i
          endIndex = if endIndex is undefined then tokens.length else endIndex
          RHStokens = tokens[index+1..endIndex-1]
          return new BinopNode operator, (parseExpression LHStokens), (parseExpression RHStokens)
  else
    return parsePrimary tokens

parseIdentifierExpression = (tokens) ->
  if tokens[1]?.value is "("
    new CallNode tokens[0].value, ""
  else 
    new IdentifierNode tokens[0].value

parseNumber = (tokens) -> new NumberNode(Number(tokens[0].value))

parseParenExpression = (tokens) ->
  level = 0; index = 0
  for token in tokens
    if token.value in ["(", "[", "{"] then level++
    if token.value in [")", "]", "}"] then level--
    if level is 0 and token.value is ")" then break
    index++
  if tokens[index+1]?.value is "->"
    params = []; paramIndex = 1
    loop
      E = parseExpression tokens[paramIndex..index], [",)"]
      params.push E
      paramIndex++ until tokens[paramIndex].value in [",", ")"]
      if tokens[paramIndex].value is ")" then break
      else paramIndex++
    index += 3 # skip to opening {
    body = []
    until tokens[index].value is "}"
      E = parseExpression tokens[index..]
      body.push E
      index++ until tokens[index].value is ";"
      index++
    new FunctionNode params, body
  else
    parseExpression tokens[1..], [")"]

parsePrimary = (tokens) ->
  switch
    when tokens[0].type is "Identifier" then parseIdentifierExpression tokens
    when tokens[0].type is "Number" then parseNumber tokens
    when tokens[0].value is "(" then parseParenExpression tokens

module.exports = parse