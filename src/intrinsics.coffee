roblangPrint = (scope, args) ->
  console.log arg.evaluate scope for arg in args

mustReturn = false
roblangReturn = (scope, args) ->
  mustReturn = args[0].evaluate scope

intrinsics = {
  print: roblangPrint
  return: roblangReturn
}

module.exports =
  intrinsics: intrinsics
  mustReturn: -> mustReturn
  resetReturn: -> mustReturn = false