local matching = import 'elasticlinkbuilder/matching.libsonnet';
local stages = import 'service-catalog/stages.libsonnet';

local rangeFilter = matching.rangeFilter;
local matchFilter = matching.matchFilter;
local matchInFilter = matching.matchInFilter;
local existsFilter = matching.existsFilter;
local mustNot = matching.mustNot;
local matchAnyScriptFilter = matching.matchAnyScriptFilter;
local matcher = matching.matcher;

local statusCode(field) =
  [rangeFilter(field, gteValue=500, lteValue=null)];

local indexDefaults = {
  defaultFilters: [],
  kibanaEndpoint: 'https://log.gprd.gitlab.net/app/kibana',
  prometheusLabelMappings: {},
  prometheusLabelTranslators: {},
};

{
  // Improve these logs when https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/11221 is addressed
  camoproxy: indexDefaults {
    timestamp: '@timestamp',
    indexPattern: 'AWz5hIoSGphUgZwzAG7q',
    defaultColumns: ['json.hostname', 'json.camoproxy_message', 'json.camoproxy_err'],
    defaultSeriesSplitField: 'json.hostname.keyword',
    failureFilter: [existsFilter('json.camoproxy_err')],
    //defaultLatencyField: 'json.grpc.time_ms',
    //latencyFieldUnitMultiplier: 1000,
  },

  consul: indexDefaults {
    timestamp: 'json.time',
    indexPattern: 'AWVDROsNO8Ra6d0I_oUl',
    defaultColumns: ['json.@module', 'json.@message'],
    requestsNotSupported: true,
  },

  fluentd: indexDefaults {
    timestamp: 'json.time',
    indexPattern: '6f3fe550-4317-11ec-8c8e-ed83b5469915',
    defaultColumns: ['json.message', 'json.type'],
    defaultSeriesSplitField: 'json.fqdn.keyword',
    requestsNotSupported: true,
    prometheusLabelMappings+: {
      // fludentd is a service to digest logs from other services. "json.type"
      // is preserved to indicate the sources of the logs.
      type: 'type',
    },
    prometheusLabelTranslators+: {
      // fluentd is treated as a part of logging service. The type is recently
      // recorded as "fluentd" instead.
      type: function(_type) 'fluentd',
    },
  },

  gitaly: indexDefaults {
    timestamp: 'json.time',
    indexPattern: 'AW5F1OHTiGcMMNRn84Di',
    defaultColumns: ['json.hostname', 'json.grpc.method', 'json.grpc.request.glProjectPath', 'json.grpc.code', 'json.grpc.time_ms'],
    defaultSeriesSplitField: 'json.grpc.method.keyword',
    failureFilter: [mustNot(matchFilter('json.grpc.code', 'OK')), existsFilter('json.grpc.code')],
    slowRequestFilter: [matchFilter('json.msg', 'unary')],
    defaultLatencyField: 'json.grpc.time_ms',
    prometheusLabelMappings+: {
      fqdn: 'json.fqdn',
    },
    latencyFieldUnitMultiplier: 1000,
  },

  gitaly_ops: self.gitaly {
    kibanaEndpoint: 'https://nonprod-log.gitlab.net/app/kibana',
    indexPattern: 'pubsub-gitaly-inf-ops',
  },

  gkeKube: indexDefaults {
    timestamp: 'json.timestamp',
    indexPattern: '1d7c16d0-c0fa-11ea-a0f8-0b8742fd907c',
    defaultColumns: ['json.jsonPayload.metadata.managedFields.manager', 'json.jsonPayload.message', 'json.jsonPayload.reason', 'json.jsonPayload.metadata.name', 'json.resource.labels.pod_name'],
    defaultSeriesSplitField: 'json.jsonPayload.metadata.managedFields.manager.keyword',
    prometheusLabelMappings+: {
      // Gke logs don't have type field. This could be solved by https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/687
      // This field filters out related components such as kubelet, kube-scheduler, kube-controller-manager, etc.
      type: 'json.jsonPayload.metadata.managedFields.manager',
    },
  },

  kas: indexDefaults {
    timestamp: 'json.time',
    indexPattern: '78f49290-709e-11eb-b821-df2c3b5b1510',
    defaultColumns: ['json.msg', 'json.project_id', 'json.commit_id', 'json.number_of_files', 'json.grpc.time_ms'],
    defaultSeriesSplitField: 'json.grpc.method.keyword',
    failureFilter: [existsFilter('json.error')],
    //defaultLatencyField: '',
    //latencyFieldUnitMultiplier: 1000,
  },

  logging: indexDefaults {
    timestamp: '@timestamp',
    indexPattern: '3fdde960-1f73-11eb-9ead-c594f004ece2',
    defaultColumns: ['log.level', 'message', 'elasticsearch.component'],
    defaultSeriesSplitField: 'elasticsearch.node.name.keyword',
    failureFilter: [matchInFilter('log.level', ['CRITICAL', 'ERROR'])],
    kibanaEndpoint: 'https://00a4ef3362214c44a044feaa539b4686.us-central1.gcp.cloud.es.io:9243/app/kibana',
  },

  mailroom: indexDefaults {
    timestamp: '@timestamp',
    indexPattern: '66d3cd70-6923-11ea-8617-2347010d3aab',
    defaultColumns: ['json.action', 'json.to_be_delivered.count', 'json.byte_size'],
    requestsNotSupported: true,
  },

  mimir: indexDefaults {
    timestamp: 'json.time',
    indexPattern: '69713556-cfad-4fcd-a7f6-7e1ac0f90313',
    defaultColumns: ['json.message', 'json.err'],
    kibanaEndpoint: 'https://nonprod-log.gitlab.net/app/kibana',
  },

  mlops: indexDefaults {
    timestamp: '@timestamp',
    indexPattern: '8cd9c4c0-f0a7-11ed-a017-0d32180b1390',
    defaultColumns: [
      'json.jsonPayload.level',
      'json.jsonPayload.method',
      'json.jsonPayload.status_code',
      'json.jsonPayload.path',
      'json.jsonPayload.duration_s',
      'json.jsonPayload.correlation_id',
    ],
    defaultLatencyField: 'json.jsonPayload.duration_s',
    defaultSeriesSplitField: 'json.jsonPayload.url',
    failureFilter: statusCode('json.jsonPayload.status_code'),
  },

  monitoring_gprd: indexDefaults {
    timestamp: '@timestamp',
    indexPattern: 'AW5ZoH2ddtvLTaJbch2P',
    defaultColumns: ['json.hostname', 'json.msg', 'json.level'],
    defaultSeriesSplitField: 'json.hostname.keyword',
    failureFilter: [matchFilter('json.level', 'error')],
  },

  monitoring_ops: self.monitoring_gprd {
    indexPattern: '0931f630-582b-11ec-87e2-4f63f28291d2',
    kibanaEndpoint: 'https://nonprod-log.gitlab.net/app/kibana',
  },

  observability: indexDefaults {
    timestamp: '@timestamp',
    indexPattern: '2b3f598d-cf5a-4186-99f0-0075d9235c57',
    defaultColumns: ['json.severity', 'json.textPayload'],
  },

  packagecloud: indexDefaults {
    timestamp: 'json.time',
    indexPattern: 'pubsub-packagecloud-inf-ops',
    defaultColumns: ['json.message', 'json.component', 'json.subcomponent'],
    kibanaEndpoint: 'https://nonprod-log.gitlab.net/app/kibana',
  },

  packagecloud_pre: self.packagecloud {
    indexPattern: 'pubsub-packagecloud-inf-pre',
  },

  pages: indexDefaults {
    timestamp: 'json.time',
    indexPattern: 'AWRaEscWMdvjVyaYlI-L',
    defaultColumns: ['json.hostname', 'json.pages_domain', 'json.host', 'json.pages_host', 'json.path', 'json.remote_ip', 'json.duration_ms'],
    defaultSeriesSplitField: 'json.pages_host.keyword',
    failureFilter: statusCode('json.status'),
    defaultLatencyField: 'json.duration_ms',
    latencyFieldUnitMultiplier: 1000,
  },

  postgres: indexDefaults {
    timestamp: '@timestamp',
    indexPattern: '97f04200-024b-11eb-81e5-155ba78758d4',
    defaultColumns: ['json.hostname', 'json.endpoint_id', 'json.error_severity', 'json.message', 'json.session_start_time', 'json.sql_state_code', 'json.duration_s', 'json.sql'],
    defaultSeriesSplitField: 'json.fingerprint.keyword',
    failureFilter: [mustNot(matchFilter('json.sql_state_code', '00000')), existsFilter('json.sql_state_code')],  // SQL Codes reference: https://www.postgresql.org/docs/9.4/errcodes-appendix.html
    defaultLatencyField: 'json.duration_s',  // Only makes sense in the context of slowlog entries
    latencyFieldUnitMultiplier: 1,
  },

  postgres_archive: self.postgres {
    defaultFilters: [matchFilter('json.type', 'archive')],
  },

  postgres_pgbouncer: indexDefaults {
    timestamp: 'json.time',
    indexPattern: '97f04200-024b-11eb-81e5-155ba78758d4',
    defaultColumns: ['json.hostname', 'json.pg_message'],
    defaultSeriesSplitField: 'json.hostname.keyword',
  },

  praefect: indexDefaults {
    timestamp: 'json.time',
    indexPattern: 'AW98WAQvqthdGjPJ8jTY',
    defaultColumns: ['json.hostname', 'json.virtual_storage', 'json.grpc.method', 'json.relative_path', 'json.grpc.code', 'json.grpc.time_ms'],
    defaultSeriesSplitField: 'json.grpc.method.keyword',
    failureFilter: [mustNot(matchFilter('json.grpc.code', 'OK')), existsFilter('json.grpc.code')],
    slowRequestFilter: [matchFilter('json.msg', 'unary')],
    defaultLatencyField: 'json.grpc.time_ms',
    latencyFieldUnitMultiplier: 1000,
  },

  pubsubbeat: indexDefaults {
    timestamp: '@timestamp',
    indexPattern: 'c1ee6e20-fbf1-11ea-af41-ad80f197fa45',
    defaultColumns: ['kubernetes.host', 'json.message'],
    defaultSeriesSplitField: 'kubernetes.host.keyword',
    prometheusLabelTranslators+: {
      // pubsubbeat is treated as a part of logging service. The type is recently
      // recorded as "pubsubbeat" instead.
      type: function(_type) 'pubsubbeat',
    },
  },

  rails: indexDefaults {
    timestamp: 'json.time',
    indexPattern: '7092c4e2-4eb5-46f2-8305-a7da2edad090',
    defaultColumns: [
      'json.status',
      'json.method',
      'json.meta.caller_id',
      'json.meta.feature_category',
      'json.path',
      'json.request_urgency',
      'json.duration_s',
      'json.target_duration_s',
    ],
    defaultSeriesSplitField: 'json.meta.caller_id.keyword',
    failureFilter: statusCode('json.status'),
    defaultLatencyField: 'json.duration_s',
    latencyFieldUnitMultiplier: 1,
    // The GraphQL requests are in the rails_graphql index and look slightly
    // different.
    defaultFilters: [mustNot(matchFilter('json.subcomponent', 'graphql_json'))],
    slowRequestFilter: [
      // These need to be present for the script to work.
      // Health check requests don't have a target_duration_s
      // This filters these out of the logs
      existsFilter('json.target_duration_s'),
      existsFilter('json.duration_s'),
      matching.matchers({ anyScript: ["doc['json.duration_s'].value > doc['json.target_duration_s'].value"] }),
    ],

    prometheusLabelMappings+: {
      stage_group: 'json.meta.feature_category',
      feature_category: 'json.meta.feature_category',
    },

    prometheusLabelTranslators+: {
      stage_group: function(groupName) { oneOf: stages.categoriesForStageGroup(groupName) },
    },
  },

  rails_ops: self.rails {
    kibanaEndpoint: 'https://nonprod-log.gitlab.net/app/kibana',
    indexPattern: 'pubsub-rails-inf-ops',
  },

  rails_graphql: self.rails {
    defaultSeriesSplitField: 'json.meta.caller_id.keyword',
    defaultColumns: ['json.meta.caller_id', 'json.operation_name', 'json.meta.feature_category', 'json.operation_fingerprint', 'json.duration_s'],
    defaultFilters: [matchFilter('json.subcomponent', 'graphql_json')],
  },

  rails_cdot: indexDefaults {
    timestamp: 'json.time',
    indexPattern: 'b881d9e0-5de8-49ce-ae7c-2b279a4f4741',
    defaultColumns: [
      'json.status',
      'json.method',
      'json.meta.feature_category',
      'json.path',
      'json.duration',
    ],
    defaultSeriesSplitField: 'json.path.keyword',
    failureFilter: statusCode('json.status'),
    defaultLatencyField: 'json.duration',
    latencyFieldUnitMultiplier: 1000,
    slowRequestFilter: [
      existsFilter('json.duration_threshold'),
      existsFilter('json.duration'),
      matching.matchers({ anyScript: ["doc['json.duration'].value > (doc['json.duration_threshold'].value * 1000)"] }),
    ],
  },

  redis: indexDefaults {
    timestamp: 'json.time',
    indexPattern: 'AWSQX_Vf93rHTYrsexmk',
    defaultColumns: ['json.hostname', 'json.redis_message'],
    defaultSeriesSplitField: 'json.hostname.keyword',
  },

  redis_slowlog: indexDefaults {
    timestamp: 'json.time',
    indexPattern: 'AWSQX_Vf93rHTYrsexmk',
    defaultColumns: ['json.hostname', 'json.command', 'json.exec_time_s'],
    defaultSeriesSplitField: 'json.hostname.keyword',
    defaultFilters: [matchFilter('json.tag', 'redis.slowlog')],
    defaultLatencyField: 'json.exec_time_s',
    latencyFieldUnitMultiplier: 1,  // Redis uses `µs`, but the field is in `s`
  },

  registry: indexDefaults {
    timestamp: 'json.time',
    indexPattern: '97ce8e90-63ad-11ea-8617-2347010d3aab',
    defaultColumns: ['json.remote_ip', 'json.duration_ms', 'json.code', 'json.msg', 'json.status', 'json.error', 'json.method', 'json.uri'],
    defaultSeriesSplitField: 'json.remote_ip',
    failureFilter: statusCode('json.status'),
    defaultLatencyField: 'json.duration_ms',
    latencyFieldUnitMultiplier: 1000,
  },

  registry_ops: self.registry {
    kibanaEndpoint: 'https://nonprod-log.gitlab.net/app/kibana',
    indexPattern: 'pubsub-registry-inf-ops',
  },

  registry_garbagecollection: indexDefaults {
    timestamp: 'json.time',
    indexPattern: '97ce8e90-63ad-11ea-8617-2347010d3aab',
    defaultColumns: ['json.correlation_id', 'json.component', 'json.worker', 'json.msg', 'json.error', 'json.duration_s'],
    defaultSeriesSplitField: 'json.worker',
    failureFilter: [matchFilter('json.level', 'error')],
    defaultLatencyField: 'json.duration_s',
  },

  runners: indexDefaults {
    timestamp: '@timestamp',
    indexPattern: 'pubsub-runner-inf-gprd',
    defaultColumns: ['json.operation', 'json.job', 'json.operation', 'json.repo_url', 'json.project', 'json.msg'],
    defaultSeriesSplitField: 'json.repo_url.keyword',
    failureFilter: [matchFilter('json.msg', 'Job failed (system failure)')],
    defaultLatencyField: 'json.duration',
    latencyFieldUnitMultiplier: 1000000000,  // nanoseconds, ah yeah
  },

  search: indexDefaults {
    kibanaEndpoint: 'https://00a4ef3362214c44a044feaa539b4686.us-central1.gcp.cloud.es.io:9243/app/kibana',
    timestamp: '@timestamp',
    indexPattern: '3fdde960-1f73-11eb-9ead-c594f004ece2',
    defaultFilters: [matchFilter('service.name', 'prod-gitlab-com indexing-20200330')],
    defaultColumns: ['elasticsearch.component', 'event.dataset', 'message'],
    requestsNotSupported: true,
  },

  shell: indexDefaults {
    timestamp: 'json.time',
    indexPattern: 'AWORyp9K1NBBQZg_dXA9',
    defaultColumns: ['json.command', 'json.msg', 'json.level', 'json.gl_project_path', 'json.error'],
    defaultSeriesSplitField: 'json.gl_project_path.keyword',
    failureFilter: [matchFilter('json.level', 'error')],
  },

  shell_ops: self.shell {
    kibanaEndpoint: 'https://nonprod-log.gitlab.net/app/kibana',
    indexPattern: 'pubsub-shell-inf-ops',
  },

  sidekiq: indexDefaults {
    timestamp: 'json.time',
    indexPattern: 'AWNABDRwNDuQHTm2tH6l',
    defaultColumns: ['json.class', 'json.queue', 'json.meta.project', 'json.job_status', 'json.queueing_duration_s', 'json.duration_s'],
    defaultSeriesSplitField: 'json.meta.project.keyword',
    failureFilter: [matchFilter('json.job_status', 'fail')],
    defaultLatencyField: 'json.duration_s',
    latencyFieldUnitMultiplier: 1,
  },

  sidekiq_execution: indexDefaults {
    timestamp: 'json.time',
    indexPattern: 'AWNABDRwNDuQHTm2tH6l',
    defaultColumns: [
      'json.class',
      'json.queue',
      'json.meta.project',
      'json.meta.feature_category',
      'json.job_status',
      'json.queueing_duration_s',
      'json.urgency',
      'json.duration_s',
      'json.target_duration_s',
    ],
    defaultSeriesSplitField: 'json.meta.project.keyword',
    failureFilter: [matchFilter('json.job_status', 'fail')],
    defaultLatencyField: 'json.duration_s',
    latencyFieldUnitMultiplier: 1,
    slowRequestFilter: [
      // These need to be present for the script to work.
      // Only job completion logs have target_duration_s and duration_s
      existsFilter('json.target_duration_s'),
      existsFilter('json.duration_s'),
      matching.matchers({ anyScript: ["doc['json.duration_s'].value > doc['json.target_duration_s'].value"] }),
    ],
  },

  sidekiq_queueing: indexDefaults {
    timestamp: 'json.time',
    indexPattern: 'AWNABDRwNDuQHTm2tH6l',
    defaultColumns: [
      'json.class',
      'json.queue',
      'json.meta.project',
      'json.job_status',
      'json.urgency',
      'json.queueing_duration_s',
      'json.target_scheduling_latency_s',
      'json.duration_s',
    ],
    defaultSeriesSplitField: 'json.meta.project.keyword',
    defaultLatencyField: 'json.queueing_duration_s',
    latencyFieldUnitMultiplier: 1,
    slowRequestFilter: [
      // These need to be present for the script to work.
      // Only job completion logs have target_duration_s and duration_s
      existsFilter('json.target_scheduling_latency_s'),
      existsFilter('json.queueing_duration_s'),
      matching.matchers({ anyScript: ["doc['json.queueing_duration_s'].value > doc['json.target_scheduling_latency_s'].value"] }),
    ],
  },

  sidekiq_execution_ops: self.sidekiq_execution {
    kibanaEndpoint: 'https://nonprod-log.gitlab.net/app/kibana',
    indexPattern: 'pubsub-sidekiq-inf-ops',
  },

  sidekiq_queueing_ops: self.sidekiq_queueing {
    kibanaEndpoint: 'https://nonprod-log.gitlab.net/app/kibana',
    indexPattern: 'pubsub-sidekiq-inf-ops',
  },

  sidekiq_cdot: indexDefaults {
    timestamp: 'json.time',
    indexPattern: '8a2718cf-f1c7-4fd8-8447-c8528d34c9e8',
    defaultColumns: [
      'json.class',
      'json.queue',
      'json.job_status',
      'json.duration',
    ],
    failureFilter: [matchFilter('json.job_status', 'fail')],
    defaultSeriesSplitField: 'json.class.keyword',
    defaultLatencyField: 'json.duration',
    latencyFieldUnitMultiplier: 1,
    slowRequestFilter: [
      existsFilter('json.duration_threshold'),
      existsFilter('json.duration'),
      matching.matchers({ anyScript: ["doc['json.duration'].value > doc['json.duration_threshold'].value"] }),
    ],
  },

  local sidekiq_viz = indexDefaults {
    defaultFilters: [
      matchFilter('json.type.keyword', 'sidekiq'),
    ],
    indexPattern: 'AWNABDRwNDuQHTm2tH6l',
    timestamp: 'json.time',
  },

  sidekiq_queueing_viz: sidekiq_viz {
    defaultLatencyField: 'json.queueing_duration_s',
  },

  sidekiq_queueing_viz_by_shard: self.sidekiq_queueing_viz {
    defaultSeriesSplitField: 'json.shard.keyword',
  },

  sidekiq_queueing_viz_by_queue: self.sidekiq_queueing_viz {
    defaultSeriesSplitField: 'json.queue.keyword',
  },

  sidekiq_queueing_viz_by_worker: self.sidekiq_queueing_viz {
    defaultSeriesSplitField: 'json.class.keyword',
  },

  sidekiq_execution_viz: sidekiq_viz {
    defaultLatencyField: 'json.duration_s',
  },

  sidekiq_execution_viz_by_worker: self.sidekiq_execution_viz {
    defaultSeriesSplitField: 'json.class.keyword',
  },

  sidekiq_execution_viz_by_shard: self.sidekiq_execution_viz {
    defaultSeriesSplitField: 'json.shard.keyword',
  },

  sidekiq_execution_viz_by_queue: self.sidekiq_execution_viz {
    defaultSeriesSplitField: 'json.queue.keyword',
  },

  workhorse: indexDefaults {
    timestamp: 'json.time',
    indexPattern: 'a4f5b470-edde-11ea-81e5-155ba78758d4',
    defaultColumns: ['json.method', 'json.remote_ip', 'json.status', 'json.uri', 'json.duration_ms'],
    defaultSeriesSplitField: 'json.remote_ip.keyword',
    failureFilter: statusCode('json.status'),
    defaultLatencyField: 'json.duration_ms',
    latencyFieldUnitMultiplier: 1000,
  },

  workhorse_ops: self.workhorse {
    kibanaEndpoint: 'https://nonprod-log.gitlab.net/app/kibana',
    indexPattern: 'pubsub-workhorse-inf-ops',
  },

  workhorse_imageresizer: indexDefaults {
    timestamp: 'json.time',
    indexPattern: 'a4f5b470-edde-11ea-81e5-155ba78758d4',
    defaultFilters: [matchFilter('json.subsystem', 'imageresizer')],
    defaultColumns: ['json.method', 'json.uri', 'json.imageresizer.content_type', 'json.imageresizer.original_filesize', 'json.imageresizer.target_width', 'json.imageresizer.status'],
    defaultSeriesSplitField: 'json.uri',
    failureFilter: [mustNot(matchFilter('json.imageresizer.status', 'success'))],
  },
}
