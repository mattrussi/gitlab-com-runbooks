// This file is autogenerated using scripts/update_stage_groups_feature_categories.rb
// Please don't update manually
{
  access: {
    name: 'Access',
    stage: 'manage',
    feature_categories: [
      'authentication_and_authorization',
      'subgroups',
      'users',
    ],
  },
  compliance: {
    name: 'Compliance',
    stage: 'manage',
    feature_categories: [
      'audit_events',
      'audit_reports',
      'compliance_management',
    ],
  },
  'import': {
    name: 'Import',
    stage: 'manage',
    feature_categories: [
      'importers',
      'internationalization',
    ],
  },
  optimize: {
    name: 'Optimize',
    stage: 'manage',
    feature_categories: [
      'devops_reports',
      'planning_analytics',
      'code_analytics',
      'value_stream_management',
      'insights',
    ],
  },
  project_management: {
    name: 'Project Management',
    stage: 'plan',
    feature_categories: [
      'issue_tracking',
      'boards',
      'time_tracking',
      'projects',
    ],
  },
  product_planning: {
    name: 'Product Planning',
    stage: 'plan',
    feature_categories: [
      'epics',
      'roadmaps',
      'design_management',
    ],
  },
  certify: {
    name: 'Certify',
    stage: 'plan',
    feature_categories: [
      'requirements_management',
      'quality_management',
      'service_desk',
    ],
  },
  source_code: {
    name: 'Source Code',
    stage: 'create',
    feature_categories: [
      'source_code_management',
    ],
  },
  code_review: {
    name: 'Code Review',
    stage: 'create',
    feature_categories: [
      'code_review',
      'editor_extension',
    ],
  },
  editor: {
    name: 'Editor',
    stage: 'create',
    feature_categories: [
      'web_ide',
      'snippets',
      'live_preview',
      'wiki',
      'static_site_editor',
      'gitlab_docs',
      'navigation',
    ],
  },
  gitaly: {
    name: 'Gitaly',
    stage: 'create',
    feature_categories: [
      'gitaly',
    ],
  },
  ecosystem: {
    name: 'Ecosystem',
    stage: 'create',
    feature_categories: [
      'api',
      'integrations',
      'gdk',
      'foundations',
      'jira_importer',
    ],
  },
  pipeline_execution: {
    name: 'Pipeline Execution',
    stage: 'verify',
    feature_categories: [
      'continuous_integration',
      'merge_trains',
      'continuous_integration_scaling',
      'pipeline_abuse_prevention',
    ],
  },
  pipeline_authoring: {
    name: 'Pipeline Authoring',
    stage: 'verify',
    feature_categories: [
      'pipeline_authoring',
      'jenkins_importer',
    ],
  },
  runner: {
    name: 'Runner',
    stage: 'verify',
    feature_categories: [
      'runner',
    ],
  },
  testing: {
    name: 'Testing',
    stage: 'verify',
    feature_categories: [
      'code_testing',
      'performance_testing',
      'usability_testing',
      'accessibility_testing',
      'build_artifacts',
    ],
  },
  package: {
    name: 'Package',
    stage: 'package',
    feature_categories: [
      'container_registry',
      'package_registry',
      'helm_chart_registry',
      'dependency_proxy',
      'dependency_firewall',
      'git_lfs',
      'release_evidence',
    ],
  },
  static_analysis: {
    name: 'Static Analysis',
    stage: 'secure',
    feature_categories: [
      'static_application_security_testing',
      'secret_detection',
      'code_quality',
    ],
  },
  dynamic_analysis: {
    name: 'Dynamic Analysis',
    stage: 'secure',
    feature_categories: [
      'dynamic_application_security_testing',
      'interactive_application_security_testing',
      'attack_emulation',
      'fuzz_testing',
    ],
  },
  composition_analysis: {
    name: 'Composition Analysis',
    stage: 'secure',
    feature_categories: [
      'dependency_scanning',
      'license_compliance',
    ],
  },
  threat_insights: {
    name: 'Threat Insights',
    stage: 'secure',
    feature_categories: [
      'vulnerability_management',
    ],
  },
  vulnerability_research: {
    name: 'Vulnerability Research',
    stage: 'secure',
    feature_categories: [
      'vulnerability_database',
      'security_benchmarking',
    ],
  },
  release: {
    name: 'Release',
    stage: 'release',
    feature_categories: [
      'continuous_delivery',
      'advanced_deployments',
      'review_apps',
      'feature_flags',
      'release_orchestration',
      'pages',
    ],
  },
  configure: {
    name: 'Configure',
    stage: 'configure',
    feature_categories: [
      'auto_devops',
      'infrastructure_as_code',
      'kubernetes_management',
      'cluster_cost_management',
      'serverless',
      'secrets_management',
      'chatops',
      'runbooks',
    ],
  },
  monitor: {
    name: 'Monitor',
    stage: 'monitor',
    feature_categories: [
      'error_tracking',
      'incident_management',
      'on_call_schedule_management',
      'metrics',
      'tracing',
      'logging',
      'synthetic_monitoring',
      'self_monitoring',
    ],
  },
  container_security: {
    name: 'Container Security',
    stage: 'protect',
    feature_categories: [
      'security_orchestration',
      'container_network_security',
      'container_host_security',
      'container_scanning',
    ],
  },
  purchase: {
    name: 'Purchase',
    stage: 'fulfillment',
    feature_categories: [
      'purchase',
    ],
  },
  license: {
    name: 'License',
    stage: 'fulfillment',
    feature_categories: [
      'license',
    ],
  },
  utilization: {
    name: 'Utilization',
    stage: 'fulfillment',
    feature_categories: [
      'utilization',
    ],
  },
  activation: {
    name: 'Activation',
    stage: 'growth',
    feature_categories: [
      'experimentation_activation',
      'onboarding',
    ],
  },
  conversion: {
    name: 'Conversion',
    stage: 'growth',
    feature_categories: [
      'experimentation_conversion',
    ],
  },
  expansion: {
    name: 'Expansion',
    stage: 'growth',
    feature_categories: [
      'experimentation_expansion',
    ],
  },
  adoption: {
    name: 'Adoption',
    stage: 'growth',
    feature_categories: [
      'experimentation_adoption',
    ],
  },
  product_intelligence: {
    name: 'Product Intelligence',
    stage: 'growth',
    feature_categories: [
      'product_analytics',
      'usage_ping',
      'service_ping',
      'privacy_control_center',
    ],
  },
  distribution: {
    name: 'Distribution',
    stage: 'enablement',
    feature_categories: [
      'omnibus_package',
      'cloud_native_installation',
    ],
  },
  geo: {
    name: 'Geo',
    stage: 'enablement',
    feature_categories: [
      'geo_replication',
      'disaster_recovery',
      'backup_restore',
    ],
  },
  memory: {
    name: 'Memory',
    stage: 'enablement',
    feature_categories: [
      'memory',
    ],
  },
  global_search: {
    name: 'Global Search',
    stage: 'enablement',
    feature_categories: [
      'global_search',
    ],
  },
  database: {
    name: 'Database',
    stage: 'enablement',
    feature_categories: [
      'database',
    ],
  },
  sharding: {
    name: 'Sharding',
    stage: 'enablement',
    feature_categories: [
      'sharding',
    ],
  },
  infrastructure: {
    name: 'Infrastructure',
    stage: 'enablement',
    feature_categories: [
      'infrastructure',
    ],
  },
  applied_ml: {
    name: 'Applied Machine Learning',
    stage: 'ModelOps',
    feature_categories: [
      'workflow_automation',
      'insider_threat',
      'intel_code_security',
    ],
  },
  mlops: {
    name: 'MLOps',
    stage: 'ModelOps',
    feature_categories: [
      'mlops',
    ],
  },
  dataops: {
    name: 'DataOps',
    stage: 'ModelOps',
    feature_categories: [
      'dataops',
    ],
  },
  moble_devops: {
    name: 'DevOps for Mobile Apps',
    stage: 'mobile',
    feature_categories: [
      'mobile_signing_deployment',
    ],
  },
  '5-min-app': {
    name: 'Five Minute Production App',
    stage: 'deploy',
    feature_categories: [
      'five_minute_production_app',
    ],
  },
}
