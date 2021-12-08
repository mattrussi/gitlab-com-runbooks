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
  testObjectWithout: {
    actual: objects.objectWithout({ hello: 'world', foo: 'bar', baz:: 'hi' }, 'foo'),
    expect: { hello: 'world', baz:: 'hi' },
  },
  testObjectWithoutIncHiddenFunction: {
    local testThing = { hello(world):: [world] },
    actual: objects.objectWithout(testThing { foo: 'bar' }, 'foo').hello('world'),
    expect: ['world'],
  },
})
