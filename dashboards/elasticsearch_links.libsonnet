local rison = import 'rison.libsonnet';

local indexes = {
  workhorse: 'AWM6itvP1NBBQZg_ElD1',
};

local defaultColumns = {
  workhorse: ['json.method', 'json.remote_ip', 'json.status', 'json.uri', 'json.duration_ms'],
};

local buildElasticDiscoverSearchQueryURL(index, filters) =
  local applicationState = {
    columns: defaultColumns[index],
    filters: [
      {
        query: f,
      }
      for f in filters
    ],
    index: indexes[index],
  };

  'https://log.gprd.gitlab.net/app/kibana#/discover?_a=' + rison.encode(applicationState);

{
  matchFilter(field, value)::
    {
      match: {
        [field]: {
          query: value,
          type: 'phrase',
        },
      },
    },

  buildElasticDiscoverSearchQueryURL(index, filters)::
    buildElasticDiscoverSearchQueryURL(index, filters),
}
