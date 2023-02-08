local watcher = (import 'deprecation_warnings.libsonnet').watcher;

watcher('pubsub-sidekiq-inf-gprd-*', 'Sidekiq', 'https://log.gprd.gitlab.net/goto/dcec0d70-a62d-11ed-9f43-e3784d7fe3ca')
