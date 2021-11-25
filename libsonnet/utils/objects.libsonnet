{
  fromPairs: function(items)
    std.foldl(
      function(object, item)
        local key = '' + item[0];

        if std.objectHas(object, key) then object else object { [key]: item[1] },
      items,
      {}
    ),
}
