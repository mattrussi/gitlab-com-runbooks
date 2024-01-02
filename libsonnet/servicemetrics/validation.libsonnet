local validateSelector(selector) =
  assert std.isObject(selector) : 'selector %s must be an object' % selector;
  selector;

{
  validateSelector: validateSelector,
}
