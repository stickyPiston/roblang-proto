class Type
  constructor: (@type) ->

class BasicType extends Type
  constructor: (@name) -> super "Basic"

class FunctionType extends Type
  constructor: (@params, @ret) -> super "Function"

class PointerType extends Type
  constructor: (@base) -> super "Pointer"

stringToType = (str) ->
  type = null
  until str is ""
    if str.match /^(i8|u8|i16|u16|u32|i32|u64|i64|void|any|bool)/
      str = str.replace /^(i8|u8|i16|u16|u32|i32|u64|i64|void|any|bool)/, (m) ->
        type = new BasicType m
        ""
    if str.match /^\*/
      str = str.replace /^\*/, (m) ->
        type = new PointerType type
        ""
    if str.match /^\(.*\)->.*/
      str = str.replace /\((.*)\)->(.*)/gm, (m, params, ret) ->
        type = new FunctionType (stringToType p.trim() for p in params.split ","), stringToType ret
        ""
  type

module.exports =
  Type: Type
  BasicType: BasicType
  FunctionType: FunctionType
  PointerType: PointerType
  stringToType: stringToType
