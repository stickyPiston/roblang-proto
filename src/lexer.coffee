class Token
  constructor: (@value, @type) ->

lex = (script) ->
  tokens = []
  until script is ""
    if script.match /^[ \r\n]+/
      script = script.replace /^[ \r\n]+/, ""
    else if script.match /^#.*#/ms
      script = script.replace /^#.*#/ms, ""
    else if script.match /^[0-9]+/
      script = script.replace /^[0-9]+/, (match) ->
        tokens.push new Token match, "Number"
        ""
    else if script.match /^->/
      script = script.replace /^->/, (match) ->
        tokens.push new Token match, "Arrow"
        ""
    else if script.match /^[A-Za-z_$][A-Za-z_$0-9]*/
      script = script.replace /^[A-Za-z_$][A-Za-z_$0-9]*/, (match) ->
        tokens.push new Token match, "Identifier"
        ""
    else if script.match /^[\[\]\(\)\{\}]/
      script = script.replace /^[\[\]\(\)\{\}]/, (match) ->
        tokens.push new Token match, "Bracket"
        ""
    else if script.match /^(\.|\|\||\||\+|\-|\/|\*|<|>|<=|>=|<<|>>|<<=|>>=|\+=|=|\-=|\/=|\*=|\|\|=|&|&&|&=|\|=|&&=|\^|~|!|==|!=|\+\+|\-\-|\^=|\^\^)/
      script = script.replace /^(\.|\|\||\/|\*|<|>|<=|>=|<<|>>|<<=|>>=|\+=|=|\-=|\/=|\*=|\||\|\|=|\+|\-|&|&&|&=|\|=|&&=|\^|~|!|==|!=|\+\+|\-\-|\^=|\^\^)/, (match) ->
        tokens.push new Token match, "Operator"
        ""
    else if script.match /^[;,:]/
      script = script.replace /^[;,:]/, (match) ->
        tokens.push new Token match, "Separator"
        ""
    else if script.match /^".*"/m
      script = script.replace /^"(.*)"/m, (match, value) ->
        tokens.push new Token value, "String"
        ""
    else
      console.error "Unrecognised token", script
      process.exit 1
  tokens
  
module.exports = lex
