{ ScopeManager, Scope } = require "./scope"

putd = (value) -> console.log value

module.exports =
  intrinsics:
    "putd": putd
