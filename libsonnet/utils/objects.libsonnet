{
  fromPairs: function(items)
    std.foldl(
      function(object, item)
        local key = '' + item[0];

        if std.objectHas(object, key) then object else object { [key]: item[1] },
      items,
      {}
    ),
  objectWithout(object, fieldToRemove):
    std.foldl(
      function(result, fieldName)
        if fieldName == fieldToRemove then
          result
        else if std.objectHas(object, fieldName) then
          result { [fieldName]: object[fieldName] }
        else
          result { [fieldName]:: object[fieldName] },
      std.objectFieldsAll(object),
      {},
    ),
}
