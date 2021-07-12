class Type
  constructor: (@type) ->

class BasicType extends Type
  constructor: (@name) -> super "Basic"

class RoblangU8 extends BasicType
  constructor: -> super "u8"

class RoblangI8 extends BasicType
  constructor: -> super "i8"

class RoblangU16 extends BasicType
  constructor: -> super "u16"

class RoblangI16 extends BasicType
  constructor: -> super "i16"

class RoblangU32 extends BasicType
  constructor: -> super "u32"

class RoblangI32 extends BasicType
  constructor: -> super "i32"

class RoblangU64 extends BasicType
  constructor: -> super "u64"

class RoblangI64 extends BasicType
  constructor: -> super "i64"

class RoblangVoid extends BasicType
  constructor: -> super "void"

class FunctionType extends Type
  constructor: (@params, @ret) -> super "Function"

class PointerType extends Type
  constructor: (@base) -> super "Pointer"

stringToType = (str) ->
  type = null
  until str is ""
    # console.log str
    if str.match /^(i8|u8|i16|u16|u32|i32|u64|i64|void)/
      str = str.replace /^(i8|u8|i16|u16|u32|i32|u64|i64|void)/, (m) ->
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
