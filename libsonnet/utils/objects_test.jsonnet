local objects = import './objects.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';

test.suite({
  testToObject: {
    actual: objects.toObject([['a', 1], ['b', [2, 3]], ['c', { d: 4 }]]),
    expect: { a: 1, b: [2, 3], c: { d: 4 } },
  },
  testToObjectIntegerKeys: {
    actual: objects.toObject([[1, 1], [2, [2, 3]], [3, { d: 4 }]]),
    expect: { '1': 1, '2': [2, 3], '3': { d: 4 } },
  },
})
