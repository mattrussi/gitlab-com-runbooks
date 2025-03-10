// This file is autogenerated using scripts/update_stage_groups_feature_categories.rb
// Please don't update manually
{
  import_and_integrate: {
    name: 'Import and Integrate',
    stage: 'foundations',
    feature_categories: [
      'api',
      'integrations',
      'webhooks',
      'importers',
      'internationalization',
    ],
  },
  personal_productivity: {
    name: 'Personal Productivity',
    stage: 'foundations',
    feature_categories: [
      'navigation',
      'settings',
      'notifications',
    ],
  },
  design_system: {
    name: 'Design System',
    stage: 'foundations',
    feature_categories: [
      'design_system',
    ],
  },
  ux_paper_cuts: {
    name: 'UX Paper Cuts',
    stage: 'foundations',
    feature_categories: [],
  },
  global_search: {
    name: 'Global Search',
    stage: 'foundations',
    feature_categories: [
      'global_search',
      'code_search',
    ],
  },
  project_management: {
    name: 'Project Management',
    stage: 'plan',
    feature_categories: [
      'team_planning',
      'service_desk',
    ],
  },
  product_planning: {
    name: 'Product Planning',
    stage: 'plan',
    feature_categories: [
      'portfolio_management',
      'okr_management',
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
      'text_editors',
      'markdown',
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
  remote_development: {
    name: 'Remote Development',
    stage: 'create',
    feature_categories: [
      'web_ide',
      'workspaces',
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
  ci_platform: {
    name: 'CI Platform',
    stage: 'verify',
    feature_categories: [
      'ci_scaling',
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
      'job_artifacts',
      'pipeline_reports',
    ],
  },
  pipeline_authoring: {
    name: 'Pipeline Authoring',
    stage: 'verify',
    feature_categories: [
      'pipeline_composition',
      'ci_variables',
      'component_catalog',
    ],
  },
  runner: {
    name: 'Runner',
    stage: 'verify',
    feature_categories: [
      'runner',
      'fleet_visibility',
    ],
  },
  hosted_runners: {
    name: 'Hosted Runners',
    stage: 'verify',
    feature_categories: [
      'hosted_runners',
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
      'virtual_registry',
      'dependency_firewall',
    ],
  },
  static_analysis: {
    name: 'Static Analysis',
    stage: 'application_security_testing',
    feature_categories: [
      'static_application_security_testing',
      'code_quality',
    ],
  },
  secret_detection: {
    name: 'Secret Detection',
    stage: 'application_security_testing',
    feature_categories: [
      'secret_detection',
    ],
  },
  dynamic_analysis: {
    name: 'Dynamic Analysis',
    stage: 'application_security_testing',
    feature_categories: [
      'dynamic_application_security_testing',
      'fuzz_testing',
      'api_security',
      'attack_emulation',
    ],
  },
  composition_analysis: {
    name: 'Composition Analysis',
    stage: 'application_security_testing',
    feature_categories: [
      'software_composition_analysis',
      'container_scanning',
    ],
  },
  vulnerability_research: {
    name: 'Vulnerability Research',
    stage: 'application_security_testing',
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
    stage: 'software_supply_chain_security',
    feature_categories: [
      'system_access',
    ],
  },
  authorization: {
    name: 'Authorization',
    stage: 'software_supply_chain_security',
    feature_categories: [
      'permissions',
      'instance_resiliency',
      'insider_threat',
    ],
  },
  compliance: {
    name: 'Compliance',
    stage: 'software_supply_chain_security',
    feature_categories: [
      'audit_events',
      'compliance_management',
      'release_evidence',
      'sscs',
    ],
  },
  pipeline_security: {
    name: 'Pipeline Security',
    stage: 'software_supply_chain_security',
    feature_categories: [
      'artifact_security',
      'secrets_management',
    ],
  },
  security_policies: {
    name: 'Security Policies',
    stage: 'security_risk_management',
    feature_categories: [
      'security_policy_management',
    ],
  },
  security_insights: {
    name: 'Security Insights',
    stage: 'security_risk_management',
    feature_categories: [
      'vulnerability_management',
      'dependency_management',
    ],
  },
  security_infrastructure: {
    name: 'Security Infrastructure',
    stage: 'security_risk_management',
    feature_categories: [],
  },
  security_platform_management: {
    name: 'Security Platform Management',
    stage: 'security_risk_management',
    feature_categories: [
      'security_testing_configuration',
      'security_asset_inventories',
      'security_testing_integrations',
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
  platform_insights: {
    name: 'Platform Insights',
    stage: 'monitor',
    feature_categories: [
      'custom_dashboards_foundation',
      'observability',
      'product_analytics',
      'incident_management',
      'on_call_schedule_management',
    ],
  },
  provision: {
    name: 'Provision',
    stage: 'fulfillment',
    feature_categories: [
      'plan_provisioning',
      'add-on_provisioning',
      'user_management',
    ],
  },
  utilization: {
    name: 'Utilization',
    stage: 'fulfillment',
    feature_categories: [
      'consumables_cost_management',
      'seat_cost_management',
    ],
  },
  fulfillment_platform: {
    name: 'Fulfillment Platform',
    stage: 'fulfillment',
    feature_categories: [
      'fulfillment_infradev',
      'customersdot_and_quote_to_cash_integrations',
      'fulfillment_internal_admin_tooling',
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
  build: {
    name: 'GitLab Build',
    stage: 'gitlab_delivery',
    feature_categories: [
      'build',
    ],
  },
  self_managed: {
    name: 'Self Managed',
    stage: 'gitlab_delivery',
    feature_categories: [
      'omnibus_package',
      'cloud_native_installation',
    ],
  },
  release: {
    name: 'GitLab Release',
    stage: 'gitlab_delivery',
    feature_categories: [
      'delivery',
    ],
  },
  deploy: {
    name: 'GitLab Deploy',
    stage: 'gitlab_delivery',
    feature_categories: [],
  },
  framework: {
    name: 'Framework',
    stage: 'gitlab_delivery',
    feature_categories: [],
  },
  ops: {
    name: 'Ops',
    stage: 'production_engineering',
    feature_categories: [
      'runway',
    ],
  },
  runway: {
    name: 'Runway',
    stage: 'production_engineering',
    feature_categories: [],
  },
  foundations: {
    name: 'Foundations',
    stage: 'production_engineering',
    feature_categories: [
      'rate_limiting',
    ],
  },
  observability: {
    name: 'Observability',
    stage: 'production_engineering',
    feature_categories: [
      'error_budgets',
      'infra_cost_data',
      'capacity_planning',
      'scalability',
    ],
  },
  cloud_connector: {
    name: 'Cloud Connector',
    stage: 'production_engineering',
    feature_categories: [
      'cloud_connector',
    ],
  },
  gitaly: {
    name: 'Gitaly',
    stage: 'data_access',
    feature_categories: [
      'gitaly',
    ],
  },
  git: {
    name: 'Git',
    stage: 'data_access',
    feature_categories: [
      'git',
    ],
  },
  database_frameworks: {
    name: 'Database Frameworks',
    stage: 'data_access',
    feature_categories: [
      'database',
    ],
  },
  database_operations: {
    name: 'Database Operations',
    stage: 'data_access',
    feature_categories: [],
  },
  durability: {
    name: 'Durability',
    stage: 'data_access',
    feature_categories: [
      'backup_restore',
      'redis',
      'sidekiq',
    ],
  },
  organizations: {
    name: 'Organizations',
    stage: 'tenant_scale',
    feature_categories: [
      'groups_and_projects',
      'user_profile',
      'organization',
    ],
  },
  cells_infrastructure: {
    name: 'Cells Infrastructure',
    stage: 'tenant_scale',
    feature_categories: [
      'cell',
    ],
  },
  geo: {
    name: 'Geo',
    stage: 'tenant_scale',
    feature_categories: [
      'geo_replication',
      'disaster_recovery',
    ],
  },
  environment_automation: {
    name: 'Environment Automation',
    stage: 'gitlab_dedicated',
    feature_categories: [
      'dedicated',
    ],
  },
  switchboard: {
    name: 'Switchboard',
    stage: 'gitlab_dedicated',
    feature_categories: [
      'switchboard',
    ],
  },
  pubsec_services: {
    name: 'US Public Sector Services',
    stage: 'gitlab_dedicated',
    feature_categories: [
      'pubsec_services',
    ],
  },
  development_analytics: {
    name: 'Development Analytics',
    stage: 'developer_experience',
    feature_categories: [],
  },
  developer_tooling: {
    name: 'Developer Tooling',
    stage: 'developer_experience',
    feature_categories: [],
  },
  engineering_productivity: {
    name: 'Engineering Productivity',
    stage: 'developer_experience',
    feature_categories: [],
  },
  feature_readiness: {
    name: 'Feature Readiness',
    stage: 'developer_experience',
    feature_categories: [],
  },
  performance_enablement: {
    name: 'Performance Enablement',
    stage: 'developer_experience',
    feature_categories: [],
  },
  test_governance: {
    name: 'Test Governance',
    stage: 'developer_experience',
    feature_categories: [],
  },
  mlops: {
    name: 'MLOps',
    stage: 'modelops',
    feature_categories: [
      'mlops',
      'ai_agents',
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
  duo_workflow: {
    name: 'Duo Workflow',
    stage: 'ai-powered',
    feature_categories: [
      'duo_workflow',
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
  custom_models: {
    name: 'Custom Models',
    stage: 'ai-powered',
    feature_categories: [
      'model_personalization',
      'self-hosted_models',
    ],
  },
  mobile_devops: {
    name: 'Mobile DevOps',
    stage: 'mobile',
    feature_categories: [
      'mobile_devops',
    ],
  },
  contributor_success: {
    name: 'Contributor Success',
    stage: 'unlisted_stage',
    feature_categories: [],
  },
  infrastructure: {
    name: 'Infrastructure',
    stage: 'unlisted_stage',
    feature_categories: [],
  },
  technical_writing: {
    name: 'Technical Writing',
    stage: 'unlisted_stage',
    feature_categories: [],
  },
}
