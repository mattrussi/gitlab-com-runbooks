local objects = import './objects.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';

test.suite({
  testFromPairs: {
    actual: objects.fromPairs([['a', 1], ['b', [2, 3]], ['c', { d: 4 }]]),
    expect: { a: 1, b: [2, 3], c: { d: 4 } },
  },
  testFromPairsIntegerKeys: {
    actual: objects.fromPairs([[1, 1], [2, [2, 3]], [3, { d: 4 }]]),
    expect: { '1': 1, '2': [2, 3], '3': { d: 4 } },
  },
  testFromPairsDuplicateKeys: {
    actual: objects.fromPairs([[1, 1], [2, [2, 3]], [1, { d: 4 }]]),
    expect: { '1': 1, '2': [2, 3] },
  },
})
