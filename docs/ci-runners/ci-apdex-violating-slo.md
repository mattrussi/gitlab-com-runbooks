## Runner Manager's queues violating the SLI of the ci-runners service

This alert has the following possible causes, in the first few minutes it is important to determine the high-level cause before investigating further, the following are the common three causes of this alert:

### GCP Quotas causing scaling issues

Look for quota-exceeded errors in logs to determine if we are hitting any GCP `gitlab-ci` project quotas that are causing scaling issues: https://log.gprd.gitlab.net/goto/8f65b43718b6e95ccf5f6972e7ca1887

Check the [Quotas Runbook](./providers/gcp/quotas.md) for more details.

**If we believe there is a GCP scaling or quota issue**:
- Contact the Runner team 24/7 using [this contact sheet](https://docs.google.com/spreadsheets/d/1JPgmmYgJxom-__vgDnvX0yyQaDPwX-XNmPsGT-S-Dvw/edit#gid=0)

### Database issue or API Errors / Saturation

- Check the [Patroni overview](https://dashboards.gitlab.net/d/patroni-main/patroni-overview?orgId=1)
- Check the [API overview](https://dashboards.gitlab.net/d/api-main/api-overview?orgId=1&from=now-1h&to=now&var-PROMETHEUS_DS=Global&var-environment=gprd)
- Check `/api/job/request` [timings in Thanos](https://thanos.gitlab.net/graph?g0.range_input=1d&g0.step_input=60&g0.max_source_resolution=0s&g0.expr=sum(avg_over_time(controller_action%3Agitlab_sql_duration_seconds_sum%3Arate1m%7Benv%3D%22gprd%22%2Ctype%3D%22api%22%2Caction%3D%22POST%20%2Fapi%2Fjobs%2Frequest%22%2Ccontroller%3D%22Grape%22%7D%5B1m%5D))%20%2F%0Asum(avg_over_time(controller_action%3Agitlab_sql_duration_seconds_count%3Arate1m%7Benv%3D%22gprd%22%2Ctype%3D%22api%22%2Caction%3D%22POST%20%2Fapi%2Fjobs%2Frequest%22%2Ccontroller%3D%22Grape%22%7D%5B1m%5D))%20*%201000&g0.tab=0&g1.range_input=1d&g1.step_input=60&g1.max_source_resolution=0s&g1.expr=histogram_quantile(0.99%2C%20sum%20by%20(le)%20(avg_over_time(controller_action%3Agitlab_sql_duration_seconds_bucket%3Arate1m%7Benv%3D%22gprd%22%2Ctype%3D%22api%22%2Caction%3D%22POST%20%2Fapi%2Fjobs%2Frequest%22%2Ccontroller%3D%22Grape%22%7D%5B1m%5D)))&g1.tab=0)
- Check [API requests for 500 errors](https://dashboards.gitlab.net/d/000000159/ci?viewPanel=91&orgId=1&var-shard=All&var-runner_type=All&var-runner_managers=All&var-gitlab_env=gprd&var-gl_monitor_fqdn=All&var-has_minutes=yes&var-runner_job_failure_reason=All&var-jobs_running_for_project=0&var-runner_request_endpoint_status=All)

**If we believe there is a problem with PostgreSQL:**
- Notify the DBRE `@Jose Finotto` with a link to the incident channel
- Page Ongres support by [creating an incident in PD](https://gitlab.pagerduty.com/service-directory/PP6HCS3?)

### Abuse

- See this note for abuse handling: https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/12776#note_530435580
- See https://gitlab.com/gitlab-com/gl-security/runbooks/-/blob/master/sirt/gitlab/cryptomining_and_ci_abuse.md for cryptomining abuse handling

**If we believe the source of the degradation is Abuse**:
- During normal working hours, notify @trust-and-safety
