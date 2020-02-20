local encodeKey(key) =
  "'" + key + "'";

local encodeArray(array, encodeUnknown) =
  local items = [
    encodeUnknown(k)
    for k in array
  ];
  '!(' + std.join(',', items) + ')';

local encodeBoolean(boolean) =
  if boolean then '!t' else '!f';

local encodeNumber(number) =
  number;

local encodeObject(object, encodeUnknown) =
  local keypairs = [
    encodeKey(k) + ':' + encodeUnknown(object[k])
    for k in std.objectFields(object)
  ];
  '(' + std.join(',', keypairs) + ')';

// TODO: handle encoding of "'" chars better
local encodeString(string) =
  "'" + string + "'";

local encodeUnknown(object) =
  if std.isArray(object) then
    encodeArray(object, encodeUnknown)
  else if std.isBoolean(object) then
    encodeBoolean(object)
  else if std.isNumber(object) then
    encodeNumber(object)
  else if std.isObject(object) then
    encodeObject(object, encodeUnknown)
  else if std.isString(object) then
    encodeString(object)
  else if object == null then
    '!n'
  else
    std.assertEqual('', 'Unknown type');

{
  encode(object):: encodeUnknown(object),
}
