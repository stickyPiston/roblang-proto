{ IdentifierNode, CallNode, BinopNode, StringLiteralNode,
  NumberNode, FunctionNode } = require "./nodes"
{ stringToType, FunctionType } = require "./types"

operators = [
  "=", "+=", "-=", "/=", "*=", "||=", "&&=", "<<=", ">>=", "&=",
  "|=", "^=", "&&", "||", "^^", "<", ">", "<=", ">=", "==", "!=",
  "+", "-", "&", "|", "^", "*", "/", "<<", ">>", "!", "~"
]

parse = (tokens) ->
  N = []
  loop
    [E, tokens] = parseExpression tokens
    tokens = tokens[1..]
    N.push E if E
    if tokens?.length is 0 or tokens is undefined then break
  N

parseExpression = (tokens, delims = [";"]) ->
  hasOperator = false
  if tokens.length is 0
    return [null, []]
  else if tokens.length isnt 1
    level = 0
    for token in tokens
      if token.value in ["(", "[", "{"] then level++
      if token.value in [")", "]", "}"] then level--
      hasOperator = hasOperator or (token.value in operators and level is 0)
  if hasOperator
    for operator in operators
      level = 0; endIndex = 0
      for token, index in tokens
        if token.value in ["(", "[", "{"] then level++
        else if token.value in [")", "]", "}"] then level--
        else if token.value is operator and level is 0
          LHStokens = tokens[..index-1]
          l = 0
          for t, i in tokens[index..]
            if t.value in delims and l is 0
              endIndex = index + i
              break
            if t.value in ["(", "[", "{"] then l++
            else if t.value in [")", "]", "}"] then l--
          endIndex = if endIndex is 0 then tokens.length else endIndex
          RHStokens = tokens[index+1..endIndex]
          return [(new BinopNode operator, (parseExpression LHStokens, delims)[0], (parseExpression RHStokens, delims)[0]), tokens[endIndex..]]
  else
    return parsePrimary tokens

parseIdentifierExpression = (tokens) ->
  if tokens[1]?.value is "("
    level = 0; args = []
    callee = tokens[0].value
    tokens = tokens[2..]
    until tokens[0].value is ")"
      if tokens[0].value is "," then tokens = tokens[1..]
      [E, tokens] = parseExpression tokens, [",", ")"]
      args.push E
    [(new CallNode callee, args), tokens[1..]]
  else if tokens[1]?.value is ":"
    [(new BinopNode ":", tokens[0].value, stringToType tokens[2].value), tokens[3..]]
  else
    [(new IdentifierNode tokens[0].value), tokens[1..]]

parseNumber = (tokens) -> [(new NumberNode Number(tokens[0].value)), tokens[1..]]

parseStringLiteral = (tokens) -> [(new StringLiteralNode tokens[0].value), tokens[1..]]

parseParenExpression = (tokens) ->
  level = 0; index = 0
  for token in tokens
    if token.value in ["(", "[", "{"] then level++
    if token.value in [")", "]", "}"] then level--
    if level is 0 and token.value is ")" then break
    index++
  if tokens[index+1]?.value is "->" or tokens[index+1]?.value is ":"
    params = []; paramIndex = 1; paramTypes = []
    loop
      [E, _] = parseExpression tokens[paramIndex..index], [")", ","]
      if E.type is "Binop"
        params.push E.LHS
        paramTypes.push E.RHS
      else params.push E
      paramIndex++ until tokens[paramIndex].value in [",", ")"]
      if tokens[paramIndex].value is ")" then break
      else paramIndex++
    returnType = null
    if tokens[++paramIndex].value is ":"
      returnType = stringToType tokens[++paramIndex].value
      paramIndex += 3
    else paramIndex += 3 # skip to opening {
    # console.log paramIndex, tokens, tokens[paramIndex]
    body = []
    index = paramIndex
    until tokens[index].value is "}"
      [E, _] = parseExpression tokens[index..]
      body.push E
      index++ until tokens[index].value is ";"
      index++
    node = new FunctionNode (params.filter Boolean), body
    node.types = new FunctionType paramTypes, returnType
    [node, tokens[index+1..]]
  else
    parseExpression tokens[1..], [")"]

parsePrimary = (tokens) ->
  switch
    when tokens[0].type is "Identifier" then parseIdentifierExpression tokens
    when tokens[0].type is "Number" then parseNumber tokens
    when tokens[0].type is "String" then parseStringLiteral tokens
    when tokens[0].value is "(" then parseParenExpression tokens
    else [null, []]

module.exports = parse