// This file is autogenerated using scripts/update_stage_groups_feature_categories.rb
// Please don't update manually
{
  import_and_integrate: {
    name: 'Import and Integrate',
    stage: 'manage',
    feature_categories: [
      'api',
      'integrations',
      'webhooks',
      'importers',
      'internationalization',
    ],
  },
  foundations: {
    name: 'Foundations',
    stage: 'manage',
    feature_categories: [
      'design_system',
      'gitlab_docs',
      'navigation',
    ],
  },
  project_management: {
    name: 'Project Management',
    stage: 'plan',
    feature_categories: [
      'team_planning',
    ],
  },
  product_planning: {
    name: 'Product Planning',
    stage: 'plan',
    feature_categories: [
      'portfolio_management',
      'design_management',
      'requirements_management',
      'quality_management',
    ],
  },
  knowledge: {
    name: 'Knowledge',
    stage: 'plan',
    feature_categories: [
      'wiki',
      'pages',
    ],
  },
  optimize: {
    name: 'Optimize',
    stage: 'plan',
    feature_categories: [
      'value_stream_management',
      'dora_metrics',
      'devops_reports',
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
      'code_review_workflow',
      'gitlab_cli',
    ],
  },
  ide: {
    name: 'IDE',
    stage: 'create',
    feature_categories: [
      'web_ide',
      'remote_development',
    ],
  },
  editor_extensions: {
    name: 'Editor Extensions',
    stage: 'create',
    feature_categories: [
      'editor_extensions',
    ],
  },
  code_creation: {
    name: 'Code Creation',
    stage: 'create',
    feature_categories: [
      'code_suggestions',
    ],
  },
  pipeline_execution: {
    name: 'Pipeline Execution',
    stage: 'verify',
    feature_categories: [
      'continuous_integration',
      'merge_trains',
      'code_testing',
      'review_apps',
      'ci-cd_visibility',
    ],
  },
  pipeline_authoring: {
    name: 'Pipeline Authoring',
    stage: 'verify',
    feature_categories: [
      'pipeline_composition',
    ],
  },
  runner: {
    name: 'Runner',
    stage: 'verify',
    feature_categories: [
      'runner',
      'runner_fleet',
    ],
  },
  runner_saas: {
    name: 'Runner SaaS',
    stage: 'verify',
    feature_categories: [
      'runner_saas',
    ],
  },
  pipeline_security: {
    name: 'Pipeline Security',
    stage: 'verify',
    feature_categories: [
      'build_artifacts',
      'secrets_management',
    ],
  },
  package_registry: {
    name: 'Package Registry',
    stage: 'package',
    feature_categories: [
      'package_registry',
      'helm_chart_registry',
    ],
  },
  container_registry: {
    name: 'Container Registry',
    stage: 'package',
    feature_categories: [
      'container_registry',
      'dependency_proxy',
      'dependency_firewall',
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
      'fuzz_testing',
      'api_security',
      'attack_emulation',
    ],
  },
  composition_analysis: {
    name: 'Composition Analysis',
    stage: 'secure',
    feature_categories: [
      'software_composition_analysis',
      'container_scanning',
    ],
  },
  vulnerability_research: {
    name: 'Vulnerability Research',
    stage: 'secure',
    feature_categories: [
      'advisory_database',
    ],
  },
  environments: {
    name: 'Environments',
    stage: 'deploy',
    feature_categories: [
      'auto_devops',
      'continuous_delivery',
      'deployment_management',
      'environment_management',
      'feature_flags',
      'infrastructure_as_code',
      'release_orchestration',
    ],
  },
  authentication: {
    name: 'Authentication',
    stage: 'govern',
    feature_categories: [
      'user_management',
      'system_access',
    ],
  },
  authorization: {
    name: 'Authorization',
    stage: 'govern',
    feature_categories: [
      'permissions',
    ],
  },
  security_policies: {
    name: 'Security Policies',
    stage: 'govern',
    feature_categories: [
      'security_policy_management',
    ],
  },
  threat_insights: {
    name: 'Threat Insights',
    stage: 'govern',
    feature_categories: [
      'vulnerability_management',
      'dependency_management',
      'sbom',
    ],
  },
  compliance: {
    name: 'Compliance',
    stage: 'govern',
    feature_categories: [
      'audit_events',
      'compliance_management',
      'release_evidence',
    ],
  },
  'anti-abuse': {
    name: 'Anti-Abuse',
    stage: 'govern',
    feature_categories: [
      'instance_resiliency',
      'insider_threat',
    ],
  },
  analytics_instrumentation: {
    name: 'Analytics Instrumentation',
    stage: 'monitor',
    feature_categories: [
      'service_ping',
      'application_instrumentation',
    ],
  },
  product_analytics: {
    name: 'Product Analytics',
    stage: 'monitor',
    feature_categories: [
      'product_analytics_visualization',
      'product_analytics_data_management',
    ],
  },
  observability: {
    name: 'Observability',
    stage: 'monitor',
    feature_categories: [
      'metrics',
      'tracing',
      'logging',
      'error_tracking',
    ],
  },
  purchase: {
    name: 'Purchase',
    stage: 'fulfillment',
    feature_categories: [
      'purchase',
      'seat_cost_management',
    ],
  },
  provision: {
    name: 'Provision',
    stage: 'fulfillment',
    feature_categories: [
      'sm_provisioning',
      'saas_provisioning',
      'commerce_integrations',
    ],
  },
  utilization: {
    name: 'Utilization',
    stage: 'fulfillment',
    feature_categories: [
      'consumables_cost_management',
    ],
  },
  fulfillment_platform: {
    name: 'Fulfillment Platform',
    stage: 'fulfillment',
    feature_categories: [
      'fulfillment_infrastructure',
      'customersdot_application',
      'fulfillment_admin_tooling',
    ],
  },
  subscription_management: {
    name: 'Subscription Management',
    stage: 'fulfillment',
    feature_categories: [
      'subscription_management',
    ],
  },
  acquisition: {
    name: 'Acquisition',
    stage: 'growth',
    feature_categories: [
      'acquisition',
      'measurement_and_locking',
      'onboarding',
    ],
  },
  activation: {
    name: 'Activation',
    stage: 'growth',
    feature_categories: [
      'activation',
    ],
  },
  distribution_build: {
    name: 'Distribution::Build',
    stage: 'systems',
    feature_categories: [
      'build',
    ],
  },
  distribution_deploy: {
    name: 'Distribution::Deploy',
    stage: 'systems',
    feature_categories: [
      'omnibus_package',
      'cloud_native_installation',
    ],
  },
  gitaly_cluster: {
    name: 'Gitaly::Cluster',
    stage: 'systems',
    feature_categories: [
      'gitaly',
    ],
  },
  gitaly_git: {
    name: 'Gitaly::Git',
    stage: 'systems',
    feature_categories: [

    ],
  },
  geo: {
    name: 'Geo',
    stage: 'systems',
    feature_categories: [
      'geo_replication',
      'disaster_recovery',
      'backup_restore',
    ],
  },
  cloud_connector: {
    name: 'Cloud Connector',
    stage: 'data_stores',
    feature_categories: [
      'cloud_connector',
    ],
  },
  global_search: {
    name: 'Global Search',
    stage: 'data_stores',
    feature_categories: [
      'global_search',
      'code_search',
    ],
  },
  database: {
    name: 'Database',
    stage: 'data_stores',
    feature_categories: [
      'database',
    ],
  },
  tenant_scale: {
    name: 'Tenant Scale',
    stage: 'data_stores',
    feature_categories: [
      'cell',
      'groups_and_projects',
      'user_profile',
      'organization',
    ],
  },
  delivery: {
    name: 'Delivery',
    stage: 'platforms',
    feature_categories: [
      'delivery',
    ],
  },
  scalability: {
    name: 'Scalability',
    stage: 'platforms',
    feature_categories: [
      'scalability',
      'error_budgets',
      'infrastructure_cost_data',
      'capacity_planning',
      'redis',
      'rate_limiting',
    ],
  },
  dedicated: {
    name: 'GitLab Dedicated',
    stage: 'platforms',
    feature_categories: [
      'dedicated',
    ],
  },
  switchboard: {
    name: 'Switchboard',
    stage: 'platforms',
    feature_categories: [
      'switchboard',
    ],
  },
  pubsec_services: {
    name: 'US Public Sector Services',
    stage: 'platforms',
    feature_categories: [
      'pubsec_services',
    ],
  },
  mlops: {
    name: 'MLOps',
    stage: 'modelops',
    feature_categories: [
      'mlops',
    ],
  },
  dataops: {
    name: 'DataOps',
    stage: 'modelops',
    feature_categories: [
      'dataops',
    ],
  },
  ai_framework: {
    name: 'AI Framework',
    stage: 'ai-powered',
    feature_categories: [
      'ai_abstraction_layer',
    ],
  },
  duo_chat: {
    name: 'Duo Chat',
    stage: 'ai-powered',
    feature_categories: [
      'duo_chat',
    ],
  },
  ai_model_validation: {
    name: 'AI Model Validation',
    stage: 'ai-powered',
    feature_categories: [
      'ai_evaluation',
      'ai_research',
    ],
  },
  mobile_devops: {
    name: 'Mobile DevOps',
    stage: 'mobile',
    feature_categories: [
      'mobile_devops',
    ],
  },
  '5-min-app': {
    name: 'Five Minute Production App',
    stage: '5-min-app',
    feature_categories: [
      'five_minute_production_app',
    ],
  },
  respond: {
    name: 'Respond',
    stage: 'service_management',
    feature_categories: [
      'incident_management',
      'on_call_schedule_management',
      'service_desk',
    ],
  },
}
