local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';
local evaluator = import 'service-maturity/evaluator.libsonnet';

local mockService = {
  type: 'mock',
  tier: 'test',
  skippedMaturityCriteria: [
    { name: 'Skipped Criteria 1', level: 'Level 1' },
    { name: 'Skipped Criteria 2', level: 'Level 2' },
  ],
};
local levels = [
  {
    name: 'All passed',
    criteria: [
      { name: 'Criteria 1', evidence: function(service) 'evidence 1' },
      { name: 'Criteria 2', evidence: function(service) ['evidence 2', 'evidence 3'] },
    ],
  },
  {
    name: 'All failed',
    criteria: [
      { name: 'Criteria 1', evidence: function(service) false },
      { name: 'Criteria 2', evidence: function(service) false },
    ],
  },
  {
    name: 'All unimplemented',
    criteria: [
      { name: 'Criteria 1', evidence: function(service) null },
      { name: 'Criteria 2', evidence: function(service) null },
    ],
  },
  {
    name: 'All skipped',
    criteria: [
      { name: 'Skipped Criteria 1', evidence: function(service) null },
      { name: 'Skipped Criteria 2', evidence: function(service) null },
    ],
  },
  {
    name: '1 failed, 1 passed',
    criteria: [
      { name: 'Criteria 1', evidence: function(service) false },
      { name: 'Criteria 2', evidence: function(service) 'evidence' },
    ],
  },
  {
    name: '2 unimplemented, 1 passed',
    criteria: [
      { name: 'Criteria 1', evidence: function(service) 'evidence' },
      { name: 'Criteria 2', evidence: function(service) null },
      { name: 'Criteria 3', evidence: function(service) null },
    ],
  },
  {
    name: '2 skipped, 1 passed',
    criteria: [
      { name: 'Skipped Criteria 1', evidence: function(service) false },
      { name: 'Criteria 1', evidence: function(service) 'evidence' },
      { name: 'Skipped Criteria 2', evidence: function(service) 'evidence' },
    ],
  },
  {
    name: '1 skipped, 1 unimplemented, 1 failed, 1 passed',
    criteria: [
      { name: 'Criteria 1', evidence: function(service) false },
      { name: 'Criteria 2', evidence: function(service) null },
      { name: 'Skipped Criteria 1', evidence: function(service) 'evidence' },
      { name: 'Criteria 3', evidence: function(service) 'evidence' },
    ],
  },
];

test.suite({
  testEvaluation: {
    actual: evaluator.evaluate(mockService, levels),
    expect: [
      {
        name: 'All passed',
        passed: true,
        criteria: [
          { name: 'Criteria 1', evidence: 'evidence 1', result: 'passed' },
          { name: 'Criteria 2', evidence: ['evidence 2', 'evidence 3'], result: 'passed' },
        ],
      },
      {
        name: 'All failed',
        passed: false,
        criteria: [
          { name: 'Criteria 1', evidence: false, result: 'failed' },
          { name: 'Criteria 2', evidence: false, result: 'failed' },
        ],
      },
      {
        name: 'All unimplemented',
        passed: false,
        criteria: [
          { name: 'Criteria 1', evidence: null, result: 'unimplemented' },
          { name: 'Criteria 2', evidence: null, result: 'unimplemented' },
        ],
      },
      {
        name: 'All skipped',
        passed: true,
        criteria: [
          { name: 'Skipped Criteria 1', evidence: null, result: 'skipped' },
          { name: 'Skipped Criteria 2', evidence: null, result: 'skipped' },
        ],
      },
      {
        name: '1 failed, 1 passed',
        passed: false,
        criteria: [
          { name: 'Criteria 1', evidence: false, result: 'failed' },
          { name: 'Criteria 2', evidence: 'evidence', result: 'passed' },
        ],
      },
      {
        name: '2 unimplemented, 1 passed',
        passed: true,
        criteria: [
          { name: 'Criteria 1', evidence: 'evidence', result: 'passed' },
          { name: 'Criteria 2', evidence: null, result: 'unimplemented' },
          { name: 'Criteria 3', evidence: null, result: 'unimplemented' },
        ],
      },
      {
        name: '2 skipped, 1 passed',
        passed: true,
        criteria: [
          { name: 'Skipped Criteria 1', evidence: null, result: 'skipped' },
          { name: 'Criteria 1', evidence: 'evidence', result: 'passed' },
          { name: 'Skipped Criteria 2', evidence: null, result: 'skipped' },
        ],
      },
      {
        name: '1 skipped, 1 unimplemented, 1 failed, 1 passed',
        passed: false,
        criteria: [
          { name: 'Criteria 1', evidence: false, result: 'failed' },
          { name: 'Criteria 2', evidence: null, result: 'unimplemented' },
          { name: 'Skipped Criteria 1', evidence: null, result: 'skipped' },
          { name: 'Criteria 3', evidence: 'evidence', result: 'passed' },
        ],
      },
    ],
  },
})
