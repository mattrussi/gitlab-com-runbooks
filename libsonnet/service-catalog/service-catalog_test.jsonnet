local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';
local serviceCatalog = import 'service-catalog/service-catalog.libsonnet';

local services = [
  {
    type: 'api',
    serviceDependencies: {
      gitaly: true,
      'redis-tracechunks': true,
      'redis-sidekiq': true,
      'redis-cache': true,
      redis: true,
    },
  },
  {
    type: 'gitaly',
    serviceDependencies: {
      gitaly: true,
    },
  },
  {
    type: 'frontend',
    serviceDependencies: {
      api: true,
    },
  },
  {
    type: 'web',
    serviceDependencies: {
      redis: true,
      gitaly: true,
    },
  },
  {
    type: 'pages',
    serviceDependencies: {
      pgbouncer: true,
    },
  },
  {
    type: 'pgbouncer',
    serviceDependencies: {
      patroni: true,
    },
  },
  { type: 'woodhouse' },
  { type: 'patroni' },
  { type: 'redis' },
  { type: 'redis-tracechunks' },
  { type: 'redis-cache' },
  { type: 'redis-sidekiq' },
];

test.suite({
  testBlank: {
    actual: serviceCatalog.buildServiceGraph(services),
    expect: {
      api: { inward: ['frontend'], outward: ['gitaly', 'redis', 'redis-cache', 'redis-sidekiq', 'redis-tracechunks'] },
      frontend: { inward: [], outward: ['api'] },
      gitaly: { inward: ['web', 'api'], outward: [] },  //  It does not include self-reference
      pages: { inward: [], outward: ['pgbouncer'] },
      patroni: { inward: ['pgbouncer'], outward: [] },
      pgbouncer: { inward: ['pages'], outward: ['patroni'] },
      redis: { inward: ['web', 'api'], outward: [] },
      'redis-cache': { inward: ['api'], outward: [] },
      'redis-sidekiq': { inward: ['api'], outward: [] },
      'redis-tracechunks': { inward: ['api'], outward: [] },
      web: { inward: [], outward: ['gitaly', 'redis'] },
      woodhouse: { inward: [], outward: [] },  // forever alone
    },
  },
})
