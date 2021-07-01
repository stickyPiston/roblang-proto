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
  constructor: (@type) -> super "Pointer"

stringToType = (str) ->
  if str in ["i8", "u8", "i16", "u16", "u32", "i32", "u64", "i64", "void"]
    new BasicType str

module.exports =
  Type: Type
  BasicType: BasicType
  FunctionType: FunctionType
  PointerType: PointerType
  stringToType: stringToType
