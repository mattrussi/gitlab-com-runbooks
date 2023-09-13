local mapping = import 'recording-rules/feature-category-mapping.libsonnet';

// This mapping is recorded globally and applicable to all environments.
// No need to separate this by env
mapping.mappingYaml({ partial_response_strategy: 'warn' })
