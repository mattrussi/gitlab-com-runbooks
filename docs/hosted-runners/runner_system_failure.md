
# HostedRunnersServiceCiRunnerJobsErrorSLOViolationSingleShard

This alert indicates that jobs are failing due to runner system failures. These failures are often related to the runner infrastructure, fleeting plugin, auto-scaling issues, or network problems. The **Failed Job Errors** chart can be used to confirm the issue.

## Possible Causes

- Runner infrastructure issues
- Docker/fleeting auto-scaling problems
- Network-related failures

## General Troubleshooting Steps

1. **Check AWS network status**
2. **Check AWS auto-scaling activity status**
     - Review the status of AWS fleeting nodes to ensure they are scaling correctly and not causing failures.
3. **Review GitLab Runner logs in OpenSearch**
     - Use the OpenSearch dashboard to examine `gitlab-runner` logs for any system failures or errors.
     - **If OpenSearch logging is not enabled** (e.g., for customers without OpenSearch logging): SSM into the runner manager instance and check the logs directly via the command:

     ```bash
     sudo journalctl -u gitlab-runner
     ```

If you find relevant information in the logs, this doc could help you resolve specific issues:
     [GitLab Runner troubleshooting](https://docs.gitlab.com/runner/faq/#general-troubleshooting-tipsd)
