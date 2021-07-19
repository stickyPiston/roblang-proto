lex = require "./lexer"
parse = require "./parser"
finalise = require "./finalise"
check = require "./checker"
compile = require "./compile"
{ readFileSync } = require "fs"

runCli = ->
  args = process.argv[2..]; filename = undefined
  `for (i = 0; i < args.length; i++) {`
  if args[i] is "-h" or args[i] is "--help"
    displayHelp()
    return
  else if args[i] is "-e"
    runScript args[i + 1]
    return
  else
    filename = args[i]
  `}`

  if filename is undefined then displayHelp()
  else runScript (readFileSync filename).toString()

runScript = (script) ->
  tokens = lex script
  nodes = parse tokens
  nodes = finalise nodes
  check nodes
  compile nodes

displayHelp = ->
  console.log """Roblang CLI:
    Usage: #{process.argv[0]} <flags> <filename>
    --help, -h: Display help
    -e: Evaluate roblang script in argument
  """

module.exports = runCli
