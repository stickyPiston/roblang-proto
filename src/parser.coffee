{ IdentifierNode, CallNode, BinopNode, StringLiteralNode,
  NumberNode, FunctionNode, IndexNode, ArrayNode } = require "./nodes"
{ stringToType, FunctionType } = require "./types"

operators = [
  "=", "+=", "-=", "/=", "*=", "||=", "&&=", "<<=", ">>=", "&=",
  "|=", "^=", "&&", "||", "^^", "<", ">", "<=", ">=", "==", "!=",
  "+", "-", "&", "|", "^", "*", "/", "<<", ">>", "!", "~"
]

parse = (tokens) ->
  expressions = [[]]; level = 0; exprIndex = 0; index = 0
  until tokens[index] is undefined or -1 is tokens.findIndex (i) -> i.value is ";"
    if tokens[index].value in ["[", "(", "{"] then level++
    if tokens[index].value in ["]", ")", "}"] then level--
    expressions[exprIndex].push tokens[index++]
    if tokens[index].value is ";" and level is 0
      exprIndex = -1 + expressions.push []
      index++
      continue
  expressions = expressions.filter (e) -> e.length
  N = []
  ### loop
    [E, tokens] = parseExpression tokens
    tokens = tokens[1..]
    N.push E if E
    if tokens?.length is 0 or tokens is undefined then break ###
  for expression in expressions
    N.push (parseExpression expression)[0]
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
      hasOperator = hasOperator or (token.value in operators and level is 0 and token.type is "Operator")

  hasOperator = false if tokens[0]?.type is "Identifier" and tokens[1]?.value is ":" and not (tokens.filter (e) -> e.value is "=").length

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
    name = tokens[0].value; typeString = ""; index = 2
    while index < tokens.length and tokens[index]?.value isnt ";"
      typeString += tokens[index].value
      index++
    [(new BinopNode ":", name, stringToType typeString), tokens[index..]]
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
      if E isnt null
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
    else paramIndex += 2 # skip to opening {
    body = []
    index = paramIndex; level = 0
    until tokens[index].value is "}" and level is 0
      if tokens[index].value in ["{", "[", "("] then level++
      else if tokens[index].value in ["}", "]", ")"] then level--
      body.push tokens[index++]
    nodes = parse body
    node = new FunctionNode (params.filter Boolean), nodes
    node.types = new FunctionType paramTypes, returnType
    [node, tokens[index+1..]]
  else
    parseExpression tokens[1..], [")"]

parseIndex = (base, tokens) ->
  [expr, tokens] = parseExpression tokens[1..], ["]"]
  [(new IndexNode base, expr), tokens[1..]]

parseArray = (tokens) ->
  tokens = tokens[1..]; items = []
  loop
    [E, tokens] = parseExpression tokens, [",", "]"]
    items.push E
    if tokens[0].value is "]" then break
    tokens = tokens[1..]
  [(new ArrayNode items), tokens[1..]]

parseChar = (tokens) -> [(new NumberNode tokens[0].value.charCodeAt 0), tokens[1..]]
  

parsePrimary = (tokens) ->
  node = undefined
  switch
    when tokens[0].type is "Identifier" then [node, tokens] = parseIdentifierExpression tokens
    when tokens[0].type is "Number" then [node, tokens] =  parseNumber tokens
    when tokens[0].type is "String" then [node, tokens] = parseStringLiteral tokens
    when tokens[0].value is "(" then [node, tokens] = parseParenExpression tokens
    when tokens[0].value is "[" then [node, tokens] = parseArray tokens
    when tokens[0].type is "Char" then [node, tokens] = parseChar tokens
    else return [null, []]
  if tokens[0]?.value is "[" then parseIndex node, tokens
  else [node, tokens]

module.exports = parse
