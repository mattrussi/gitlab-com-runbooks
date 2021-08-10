local misc = import './misc.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';

test.suite({
  testAllFalse: {
    actual: misc.all(function(num) num % 2 == 0, [0, 1, 2, 3]),
    expect: false,
  },
  testAllTrue: {
    actual: misc.all(function(num) num % 2 == 0, [0, 2, 4, 6]),
    expect: true,
  },
  testAllEmpty: {
    actual: misc.all(function(num) num % 2 == 0, []),
    expect: true,
  },
  testAnyFalse: {
    actual: misc.any(function(num) num % 2 == 0, [1, 3, 5, 7, 9]),
    expect: false,
  },
  testAnyTrue: {
    actual: misc.any(function(num) num % 2 == 0, [0, 1, 3, 5, 7]),
    expect: true,
  },
  testAnyEmpty: {
    actual: misc.any(function(num) num % 2 == 0, []),
    expect: false,
  },
  testIsPresentNull: {
    actual: misc.isPresent(null),
    expect: false,
  },
  testIsPresentNullValue: {
    actual: misc.isPresent(null, 'null_value'),
    expect: 'null_value',
  },
  testIsPresentObject: {
    actual: misc.isPresent({ a: 1 }),
    expect: true,
  },
  testIsPresentObjectEmpty: {
    actual: misc.isPresent({}),
    expect: false,
  },
  testIsPresentArray: {
    actual: misc.isPresent([1, 3, 4]),
    expect: true,
  },
  testIsPresentArrayEmpty: {
    actual: misc.isPresent([]),
    expect: false,
  },
  testIsPresentTrue: {
    actual: misc.isPresent(true),
    expect: true,
  },
  testIsPresentFalse: {
    actual: misc.isPresent(false),
    expect: false,
  },
  testArrayDiff: {
    actual: misc.arrayDiff(['a', 'b', 'c', 'd'], ['b', 'c', 'e']),
    expect: ['a', 'd'],
  },
  testArrayDiffDuplicated: {
    actual: misc.arrayDiff(['a', 'a', 'b', 'c', 'c', 'c', 'd'], ['b', 'c', 'e']),
    expect: ['a', 'a', 'c', 'c', 'd'],
  },
  testArrayDiffEmptyArrayLeft: {
    actual: misc.arrayDiff([], ['b', 'c', 'e']),
    expect: [],
  },
  testArrayDiffEmptyArrayRight: {
    actual: misc.arrayDiff(['a', 'b', 'c'], []),
    expect: ['a', 'b', 'c'],
  },
})
