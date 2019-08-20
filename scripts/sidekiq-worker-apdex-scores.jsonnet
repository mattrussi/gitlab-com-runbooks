// This file is used to generate `rules/sidekiq-worker-apdex-scores.yml`
// Please be sure to run `scripts/generate-sidekiq-worker-apdex-scores.sh` after changing this file

// Weekly p95 job execution duration values
// Calculated using the following ELK query: https://log.gitlab.net/goto/3bd0a288bd965a9e5ada6869740ae54c
// Our thanos cluster is unable to handle this query, but if could it would
// be: `histogram_quantile(0.99, sum(rate(sidekiq_jobs_completion_seconds_bucket{environment="gprd"}[1w])) by (le, queue, environment))`
local P99_VALUES_FOR_QUEUES = {
  "cronjob:expire_build_artifacts": 2723.086,
  "import_issues_csv": 694.804,
  "cronjob:import_export_project_cleanup": 686.253,
  "cronjob:pipeline_schedule": 626.692,
  "project_export": 459.545,
  "invalid_gpg_signature_update": 385.959,
  "repository_cleanup": 373.906,
  "cronjob:update_max_seats_used_for_gitlab_com_subscriptions": 344.92,
  "cronjob:gitlab_usage_ping": 339.92,
  "delete_merged_branches": 240.083,
  "cronjob:remove_expired_members": 234.193,
  "repository_import": 180.9,
  "export_csv": 174.309,
  "cronjob:ci_archive_traces_cron": 169.422,
  "repository_fork": 148.61,
  "pages": 147.896,
  "container_repository:delete_container_repository": 143.195,
  "cronjob:stuck_ci_jobs": 121.5,
  "group_destroy": 118.058,
  "pipeline_default:store_security_reports": 100.996,
  "repository_update_remote_mirror": 80.89,
  "merge": 76.944,
  "cronjob:stuck_import_jobs": 72.014,
  "container_repository:cleanup_container_repository": 70.78,
  "cronjob:namespaces_prune_aggregation_schedules": 69.766,
  "gcp_cluster:cluster_upgrade_app": 62.337,
  "pipeline_processing:ci_build_prepare": 60.508,
  "gcp_cluster:cluster_patch_app": 58.283,
  "delete_user": 55.599,
  "reactive_caching": 54.725,
  "rebase": 50.893,
  "project_destroy": 42.849,
  "cronjob:pages_domain_verification_cron": 41.732,
  "github_importer:github_import_stage_import_repository": 40.742,
  "pipeline_processing:build_process": 37.721,
  "delete_stored_files": 34.515,
  "cronjob:issue_due_scheduler": 30.865,
  "pipeline_creation:run_pipeline_schedule": 30.777,
  "gcp_cluster:cluster_install_app": 29.227,
  "pipeline_processing:build_queue": 28.153,
  "create_gpg_signature": 25.656,
  "cronjob:repository_archive_cache": 24.858,
  "emails_on_push": 22.227,
  "cronjob:pages_domain_ssl_renewal_cron": 21.73,
  "post_receive": 21.421,
  "github_importer:github_import_stage_import_issues_and_diff_notes": 19.407,
  "cronjob:remove_unreferenced_lfs_objects": 19.304,
  "create_github_webhook": 18.642,
  "github_importer:github_import_stage_import_pull_requests": 17.7,
  "gcp_cluster:clusters_applications_uninstall": 15.801,
  "cronjob:historical_data": 15.587,
  "pipeline_processing:pipeline_process": 15.518,
  "cronjob:trending_projects": 15.428,
  "cronjob:prune_web_hook_logs": 15.219,
  "mail_scheduler:mail_scheduler_issue_due": 15.195,
  "new_epic": 14.525,
  "github_importer:github_import_stage_finish_import": 13.63,
  "pipeline_default:ci_create_cross_project_pipeline": 12.51,
  "pipeline_creation:create_pipeline": 11.871,
  "elastic_indexer": 11.398,
  "github_import_advance_stage": 11.37,
  "pipeline_background:archive_trace": 10.194,
  "incident_management:incident_management_process_alert": 10.033,
  "gcp_cluster:cluster_wait_for_app_installation": 9.843,
  "repository_update_mirror": 9.813,
  "new_merge_request": 9.528,
  "detect_repository_languages": 8.955,
  "deployment:deployments_success": 8.431,
  "github_importer:github_import_stage_import_notes": 7.936,
  "elastic_commit_indexer": 7.391,
  "gcp_cluster:wait_for_cluster_creation": 7.325,
  "github_importer:github_import_stage_import_base_data": 6.982,
  "mailers": 6.93,
  "cronjob:remove_expired_group_links": 6.905,
  "github_importer:github_import_stage_import_lfs_objects": 6.842,
  "email_receiver": 6.825,
  "git_garbage_collect": 6.516,
  "pages_domain_ssl_renewal": 6.176,
  "gcp_cluster:clusters_applications_wait_for_uninstall_app": 6.104,
  "mail_scheduler:mail_scheduler_notification_service": 5.792,
  "create_note_diff_file": 5.722,
  "gcp_cluster:cluster_provision": 5.638,
  "cronjob:stuck_merge_jobs": 5.528,
  "new_note": 4.871,
  "new_issue": 4.798,
  "web_hook": 4.209,
  "pipeline_processing:build_finished": 4.134,
  "pipeline_processing:ci_build_schedule": 4.1,
  "deployment:deployments_finished": 4.039,
  "update_merge_requests": 4.029,
  "cronjob:geo_sidekiq_cron_config": 3.976,
  "github_importer:github_import_import_pull_request": 3.943,
  "todos_destroyer:todos_destroyer_entity_leave": 3.868,
  "gcp_cluster:cluster_wait_for_ingress_ip_address": 3.467,
  "project_service": 3.434,
  "chat_notification": 3.341,
  "auto_merge:auto_merge_process": 3.107,
  "object_pool:object_pool_join": 3.09,
  "cronjob:update_all_mirrors": 2.838,
  "update_project_statistics": 2.697,
  "pipeline_hooks:pipeline_hooks": 2.66,
  "update_namespace_statistics:namespaces_root_statistics": 2.542,
  "pipeline_cache:expire_pipeline_cache": 2.535,
  "process_commit": 2.318,
  "project_cache": 2.27,
  "pages_domain_verification": 2.253,
  "object_pool:object_pool_create": 1.962,
  "github_importer:github_import_refresh_import_jid": 1.857,
  "auto_devops:auto_devops_disable": 1.802,
  "cronjob:prune_old_events": 1.729,
  "github_importer:github_import_import_diff_note": 1.696,
  "pipeline_default:pipeline_notification": 1.675,
  "github_importer:github_import_import_issue": 1.666,
  "delete_diff_files": 1.658,
  "irker": 1.61,
  "repository_remove_remote": 1.569,
  "background_migration": 1.506,
  "pipeline_background:ci_build_trace_chunk_flush": 1.506,
  "todos_destroyer:todos_destroyer_confidential_issue": 1.487,
  "cronjob:pages_domain_removal_cron": 1.46,
  "update_namespace_statistics:namespaces_schedule_aggregation": 1.447,
  "project_daily_statistics": 1.441,
  "pipeline_hooks:build_hooks": 1.436,
  "pipeline_default:sync_security_reports_to_report_approval_rules": 1.295,
  "remote_mirror_notification": 1.232,
  "github_importer:github_import_import_note": 1.064,
  "object_pool:object_pool_schedule_join": 1.047,
  "todos_destroyer:todos_destroyer_private_features": 1.042,
  "todos_destroyer:todos_destroyer_project_private": 1.035,
  "authorized_projects": 0.98,
  "todos_destroyer:todos_destroyer_group_private": 0.96,
  "pipeline_processing:stage_update": 0.882,
  "gitlab_shell": 0.857,
  "project_import_schedule": 0.832,
  "pipeline_processing:pipeline_update": 0.763,
  "pipeline_default:pipeline_metrics": 0.717,
  "pipeline_cache:expire_job_cache": 0.653,
  "cronjob:schedule_migrate_external_diffs": 0.596,
  "pipeline_processing:build_success": 0.591,
  "pipeline_processing:update_head_pipeline_for_merge_request": 0.565,
  "cronjob:pseudonymizer": 0.537,
  "cronjob:ldap_all_groups_sync": 0.529,
  "pipeline_processing:pipeline_success": 0.377,
  "object_pool:object_pool_destroy": 0.271,
  "cronjob:requests_profiles": 0.235,
  "cronjob:ldap_sync": 0.134,
  "cronjob:admin_email": 0.113,
};

// --------------------------------------------------------

// Returns the next biggest latency bucket for a given latency.
// These should match the values in
// `count(sidekiq_jobs_completion_seconds_bucket{environment="gprd"}) by (le)`
local thresholdForLatency(latency) =
  if latency < 0.1 then
    "0.1"
  else if latency < 0.25 then
    "0.25"
  else if latency < 0.5 then
    "0.5"
  else if latency < 1 then
    "1"
  else if latency < 2.5 then
    "2.5"
  else if latency < 5 then
    "5"
  else if latency < 10 then
    "10"
  else if latency < 25 then
    "25"
  else if latency < 60 then
    "60"
  else if latency < 300 then
    "300"
  else if latency < 600 then
    "600"
  else
    "+Inf";

// Groups each queue by its apdex threshold
local latencyGroups =
  local addQueueToGroup(groups, queue) =
    local threshold = thresholdForLatency(P99_VALUES_FOR_QUEUES[queue]);
    groups + {
      [threshold]+: [queue]
    };

  std.foldl(addQueueToGroup, std.objectFields(P99_VALUES_FOR_QUEUES), {});

// Converts an array of queues into a prometheus regular expression matcher
local arrayToRegExp(queues) = std.join('|', queues);

// Given a threshold and list of queues, generates the appropriate prometheus Apdex expression
local apdexScoreForQueues(threshold, queues) =
  'sum(rate(sidekiq_jobs_completion_seconds_bucket{le="' + threshold + '", queue=~"' + arrayToRegExp(queues) + '"}[1m])) by (environment, queue, stage, tier, type)
   /
   sum(rate(sidekiq_jobs_completion_seconds_bucket{le="+Inf", queue=~"' + arrayToRegExp(queues) + '"}[1m])) by (environment, queue, stage, tier, type) >= 0';

local recordingRuleForThresholdAndQueues(threshold, queues) =
  {
    record: "gitlab_background_worker_queue_duration_apdex:ratio",
    labels: {
      threshold: threshold
    },
    expr: apdexScoreForQueues(threshold, queues)
  };

local excludeInfThreshold(threshold) = threshold != "+Inf";

local rulesFile = {
  groups: [{
    name: "sidekiq-queue-apdex-scores.rules",
    rules: [
      recordingRuleForThresholdAndQueues(threshold, latencyGroups[threshold]) for threshold in std.filter(excludeInfThreshold, std.objectFields(latencyGroups))
    ]
  }]
};

std.manifestYamlDoc(rulesFile)
