# How to detect CI Abuse

- Check [started jobs by project](https://log.gprd.gitlab.net/goto/63f83c2a163fb0b29edc33b19773db25).

# Summary

**Note**: There is additional coverage by trust-and-safety to handle CI abuse up until April 15th, 2021: gitlab-com/gl-security/security-operations/trust-and-safety/operations#509 (see [spreadsheet](https://docs.google.com/spreadsheets/d/1KRGdGvPDWekGFYTPIjN8PAdB3ya283Xj2ydFjJr6U70/edit#gid=673454602) for coverage)

**For all issues be sure to also notify `@trust-and-safety` on Slack**

Be sure to join the `#ci-abuse-alerting` private Slack channel for abuse reports

For information about how to handle certain types of CI abuse, see the [SIRT runbook](https://gitlab.com/gitlab-com/gl-security/runbooks/-/blob/master/sirt/gitlab/cryptomining_and_ci_abuse.md). (gitlab internal)

- For blocking users see the Scrubber Runbook: https://gitlab.com/gitlab-com/gl-security/runbooks/-/blob/ad11eaf0771badcc9a7ae24885e5f969b420b37a/trust_and_safety/Abuse_Mitigation_Bouncer_Web.md
- For all issues be sure to also notify `@trust-and-safety` on Slack
- Additional methods of finding potential abusers [issues/12776](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/12776#note_530435580)):

## Helpful monitoring links

- [Kibana visualization of started jobs](https://log.gprd.gitlab.net/goto/baca81ec588b366ca0ec68ff6d5e5322)
- [CI pending builds](https://thanos.gitlab.net/graph?g0.range_input=1h&g0.max_source_resolution=0s&g0.expr=sum(ci_pending_builds%7Bfqdn%3D~%22postgres-dr-archive-01-db-gprd%5C%5C.c%5C%5C.gitlab-production%5C%5C.internal%22%2C%20shared_runners%3D%22yes%22%2Chas_minutes%3D~%22yes%22%7D)%20by%20(namespace)%20%3E%20200&g0.tab=0)
- [GCP "Security Command Center"](https://console.cloud.google.com/security/command-center/findings?view_type=vt_severity_type&organizationId=769164969568&orgonly=true&supportedpurview=organizationId&vt_severity_type=All&columns=category,resourceName,eventTime,createTime,parent,securityMarks.marks)
