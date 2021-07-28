class Scope
  constructor: () ->
    @variables = {}
    @scopeChanges = [[]]
    @currentChangeIndex = 0

  changeScope: () -> @currentChangeIndex = -1 + @scopeChanges.push []

  revertChanges: () ->
    delete @variables[name] for name in @scopeChanges[@currentChangeIndex]
    @scopeChanges.pop()
    @currentChangeIndex--

  saveVariable: (name, value) ->
    @variables[name] = value
    inChangesArray = `this.scopeChanges.reduce((acc, changes) => acc || changes.includes(name), false)`
    if not inChangesArray
      @scopeChanges[@currentChangeIndex].push name

  recallVariable: (name) ->
    @variables[name]

module.exports = Scope
