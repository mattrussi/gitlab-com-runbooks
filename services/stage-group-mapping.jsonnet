// This file is autogenerated using scripts/update_stage_groups_feature_categories.rb
// Please don't update manually
{
  authentication_and_authorization: {
    name: 'Authentication and Authorization',
    stage: 'manage',
    feature_categories: [
      'authentication_and_authorization',
      'permissions',
      'user_management',
      'credential_management',
      'system_access',
    ],
  },
  organization: {
    name: 'Organization',
    stage: 'manage',
    feature_categories: [
      'subgroups',
      'user_profile',
      'projects',
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
  integrations: {
    name: 'Integrations',
    stage: 'manage',
    feature_categories: [
      'api',
      'integrations',
      'webhooks',
    ],
  },
  foundations: {
    name: 'Foundations',
    stage: 'manage',
    feature_categories: [
      'design_system',
      'navigation',
    ],
  },
  project_management: {
    name: 'Project Management',
    stage: 'plan',
    feature_categories: [
      'team_planning',
      'planning_analytics',
    ],
  },
  product_planning: {
    name: 'Product Planning',
    stage: 'plan',
    feature_categories: [
      'portfolio_management',
      'design_management',
    ],
  },
  certify: {
    name: 'Certify',
    stage: 'plan',
    feature_categories: [
      'requirements_management',
      'quality_management',
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
  editor: {
    name: 'Editor',
    stage: 'create',
    feature_categories: [
      'web_ide',
      'wiki',
      'pages',
      'remote_development',
    ],
  },
  pipeline_execution: {
    name: 'Pipeline Execution',
    stage: 'verify',
    feature_categories: [
      'continuous_integration',
      'merge_trains',
    ],
  },
  pipeline_authoring: {
    name: 'Pipeline Authoring',
    stage: 'verify',
    feature_categories: [
      'pipeline_authoring',
      'secrets_management',
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
  pipeline_insights: {
    name: 'Pipeline Insights',
    stage: 'verify',
    feature_categories: [
      'code_testing',
      'performance_testing',
      'build_artifacts',
      'review_apps',
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
      'interactive_application_security_testing',
      'attack_emulation',
    ],
  },
  composition_analysis: {
    name: 'Composition Analysis',
    stage: 'secure',
    feature_categories: [
      'dependency_scanning',
      'container_scanning',
      'license_compliance',
    ],
  },
  vulnerability_research: {
    name: 'Vulnerability Research',
    stage: 'secure',
    feature_categories: [
      'advisory_database',
      'security_benchmarking',
    ],
  },
  'anti-abuse': {
    name: 'Anti-Abuse',
    stage: 'anti-abuse',
    feature_categories: [
      'instance_resiliency',
      'insider_threat',
    ],
  },
  release: {
    name: 'Release',
    stage: 'release',
    feature_categories: [
      'continuous_delivery',
      'advanced_deployments',
      'feature_flags',
      'release_orchestration',
      'release_evidence',
      'environment_management',
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
      'deployment_management',
    ],
  },
  respond: {
    name: 'Respond',
    stage: 'monitor',
    feature_categories: [
      'incident_management',
      'on_call_schedule_management',
      'runbooks',
      'continuous_verification',
      'service_desk',
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
    ],
  },
  product_intelligence: {
    name: 'Product Intelligence',
    stage: 'analytics',
    feature_categories: [
      'service_ping',
      'application_instrumentation',
    ],
  },
  product_analytics: {
    name: 'Product Analytics',
    stage: 'analytics',
    feature_categories: [
      'product_analytics',
    ],
  },
  purchase: {
    name: 'Purchase',
    stage: 'fulfillment',
    feature_categories: [
      'purchase',
    ],
  },
  provision: {
    name: 'Provision',
    stage: 'fulfillment',
    feature_categories: [
      'sm_provisioning',
      'saas_provisioning',
    ],
  },
  utilization: {
    name: 'Utilization',
    stage: 'fulfillment',
    feature_categories: [
      'subscription_cost_management',
    ],
  },
  fulfillment_platform: {
    name: 'Fulfillment Platform',
    stage: 'fulfillment',
    feature_categories: [
      'fulfillment_infrastructure',
      'customersdot_application',
    ],
  },
  billing_and_subscription_management: {
    name: 'Billing and Subscription Management',
    stage: 'fulfillment',
    feature_categories: [
      'billing_and_payments',
      'subscription_management',
    ],
  },
  commerce_integrations: {
    name: 'Commerce Integrations',
    stage: 'fulfillment',
    feature_categories: [
      'commerce_integrations',
    ],
  },
  fulfillment_admin_tooling: {
    name: 'Fulfillment Admin Tooling',
    stage: 'fulfillment',
    feature_categories: [
      'fulfillment_admin_tooling',
    ],
  },
  acquisition: {
    name: 'Acquisition',
    stage: 'growth',
    feature_categories: [
      'experimentation_conversion',
      'experimentation_expansion',
      'onboarding',
    ],
  },
  activation: {
    name: 'Activation',
    stage: 'growth',
    feature_categories: [
      'experimentation_adoption',
      'experimentation_activation',
    ],
  },
  distribution_build: {
    name: 'Distribution:Build',
    stage: 'systems',
    feature_categories: [
      'build',
    ],
  },
  distribution_deploy: {
    name: 'Distribution:Deploy',
    stage: 'systems',
    feature_categories: [
      'omnibus_package',
      'cloud_native_installation',
    ],
  },
  gitaly_cluster: {
    name: 'Gitaly:Cluster',
    stage: 'systems',
    feature_categories: [
      'gitaly',
    ],
  },
  gitaly_git: {
    name: 'Gitaly:Git',
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
  application_performance: {
    name: 'Application Performance',
    stage: 'data_stores',
    feature_categories: [
      'application_performance',
      'redis',
      'rate_limiting',
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
  pods: {
    name: 'Pods',
    stage: 'data_stores',
    feature_categories: [
      'pods',
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
    ],
  },
  dedicated: {
    name: 'GitLab Dedicated',
    stage: 'platforms',
    feature_categories: [
      'dedicated',
    ],
  },
  pubsec_services: {
    name: 'US Public Sector Services',
    stage: 'platforms',
    feature_categories: [
      'pubsec_services',
    ],
  },
  ai_assisted: {
    name: 'AI Assisted',
    stage: 'modelops',
    feature_categories: [
      'workflow_automation',
      'intel_code_security',
      'code_suggestions',
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
  mobile_devops: {
    name: 'Mobile DevOps',
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
  no_code_automation: {
    name: 'No-code Automation',
    stage: 'no_code',
    feature_categories: [
      'no_code_automation',
    ],
  },
}
