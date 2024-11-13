# HostedRunnersServicePendingBuildsSaturationSingleShard

## Description

This alert indicates that there is a large number of CI pending builds, signaling potential issues with runner performance or capacity.

## General Troubleshooting Steps

1. **Check Hosted Runner Dashboard**
   - Verify the dashboard to confirm there is a large number of pending CI builds.

2. **Verify Runner Health**
   - Ensure the runner is working correctly and not experiencing a high number of errors.

3. **Check AWS Fleeting Machines**
   - Verify that AWS fleeting machines are being created successfully by checking the AWS dashboard or the logging dashboards.
   - You should see logs like the following, indicating that instances are being created:

     ```text
     gitlab-runner[3066]: increasing instances
     ```

4. **Debugging Fleeting Errors**
   - If you do not see the expected log entries, check the logs for any fleeting-related errors to help identify and resolve the issue.
