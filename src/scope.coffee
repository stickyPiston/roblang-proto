class ScopeManager
  constructor: -> @scopes = []

  add: (scope) -> (@scopes.push scope) - 1
  get: (index) -> @scopes[index]
  set: (index, name, value) -> @scopes[index].set name, value
  recall: (index, name) ->
    if @scopes[index]? then @scopes[index].recall name
    else throw new Error "Call to undefined variable"

scopeManager = new ScopeManager

class Scope
  constructor: (@parents...) ->
    @variables = {}
  
  set: (name, value) ->
    if name of @variables
      @variables[name] = value
    else
      for index in @parents
        if (scopeManager.recall index, name) isnt undefined
          scopeManager.set index, name, value 
          return
      @variables[name] = value

  recall: (name) ->
    if name of @variables
      return @variables[name]
    else
      for index in @parents
        val = scopeManager.recall index, name
        return val if val
    undefined

module.exports =
  ScopeManager: scopeManager
  Scope: Scope