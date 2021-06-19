{ ScopeManager, Scope } = require "./scope"

roblangPrint = (scope, args) ->
  console.log arg.evaluate scope for arg in args

mustReturn = false
roblangReturn = (scope, args) ->
  mustReturn = args[0].evaluate scope

roblangIf = (scope, args) ->
  cond = args[0].evaluate scope
  returnValue = (val) ->
      if val.type is "Function"
        newScope = ScopeManager.add new Scope scope
        for N in val.body
          N.evaluate(newScope)
          if mustReturn isnt false
            [ret, mustReturn] = [mustReturn, false]
            return ret
      else
        return val.evaluate scope
  if args.length is 3
    if cond is true then returnValue args[1]
    else returnValue args[2]
  else if args.length is 2
    if cond is true then returnValue args[1]
    else return undefined
  else
    throw new Error("Invalid number of arguments")

module.exports =
  intrinsics:
    "putd": roblangPrint
    "return": roblangReturn
    "if": roblangIf 
  mustReturn: -> mustReturn
  resetReturn: -> mustReturn = false