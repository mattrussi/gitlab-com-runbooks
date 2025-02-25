aws s3control create-job \
  --account-id 601177344057 \
  --operation '{"S3InitiateRestoreObject": {"ExpirationInDays": 7, "GlacierJobTier": "STANDARD"}}' \
  --manifest '{"Spec": {"Format": "S3BatchOperations_CSV_20180820"}, "Location": {"ObjectArn": "arn:aws:s3:::playpensandbox-hosted-runner-usage"}}' \
  --priority 1 \
  --report '{"Bucket": "arn:aws:s3:::playpensandbox-hosted-runner-report", "Format": "Report_CSV_20180820", "Enabled": true, "Prefix": "batch-job-report"}' \
  --role-arn arn:aws:iam::601177344057:role/gitlab/dedicated/playpensandbox/playpensandbox-runner-s3-replication-role \
  --confirmation-required
