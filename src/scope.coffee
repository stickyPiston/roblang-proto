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
    if @scopeChanges.reduce ((changes, acc) -> acc ||= name in changes), false
      @scopeChanges[@currentChangeIndex].push name

  recallVariable: (name) ->
    @variables[name]

module.exports = Scope
