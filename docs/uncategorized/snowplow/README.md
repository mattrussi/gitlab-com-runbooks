# [SnowPlow](https://github.com/snowplow/snowplow/wiki/snowplow-tracker-protocol)

**Table of Contents**

[TOC]

SnowPlow is a pipeline of nodes and streams that is used to accept events from the GitLab.com front-end web tracker. The tracker is JavaScript that is executed by a user's browser.

All of the SnowPlow pipeline components live in AWS GPRD account: `855262394183`.

* [Design Document](https://about.gitlab.com/handbook/engineering/infrastructure/design/snowplow/)
* [Terraform Configuration](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/tree/master/environments/aws-snowplow)
* [CloudWatch Dashboard](https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=SnowPlow)

## The Pipeline Diagram

![SnowPlow Diagram](../img/snowplow/snowplowdiagram.png "SnowPlow Diagram")

## What is important?

If you are reading this, most likely one of two things has gone wrong. Either the SnowPlow pipeline has stopped accepting events or it has stopped writing events to the S3 bucket. Not accepting requests is a big problem and it should be fixed as soon as possible. Collecting events is important and a synchronous process.

Processing events and writing them out is important, but not as time-sensitive.  There is some slack in the queue to allow events to stack up before being written.

The raw events Kinesis stream has a data retention period of 48 hours. This can be altered if needed in a dire situation [aws-snowplow-prd/main.tf](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/main/environments/aws-snowplow-prd/main.tf?ref_type=heads), and searching for `retention_period` argument.

## Not accepting requests

1. A quick curl check should give you a good response of **OK**. This same URL is used for individual collector nodes to check health against port 8000:

    * `curl https://snowplowprd.trx.gitlab.net/health`

1. Log into GPRD AWS and verify that there are collector nodes in the
  [SnowPlowNLBTargetGroup](https://us-east-2.console.aws.amazon.com/ec2/home?region=us-east-2#TargetGroup:targetGroupArn=arn:aws:elasticloadbalancing:us-east-2:855262394183:targetgroup/SnowPlowPRDNLBTargetGroup/643ac960b36da760) target group. If not, something has gone wrong
  with the [snowplow PRD collector](https://us-east-2.console.aws.amazon.com/ec2/home?region=us-east-2#AutoScalingGroupDetails:id=snowplow%2520PRD%2520collector;view=details) Auto Scaling group.
1. Check Cloudflare and verify that `snowplowprd.trx.gitlab.net` is still
  pointing to the [EC2 SnowPlow load balancer](https://us-east-2.console.aws.amazon.com/ec2/home?region=us-east-2#LoadBalancers:) DNS name. The record in Cloudflare should be a `CNAME`.
1. If there are collectors running, you can SSH into the instance and then check the logs by running:

    ```sh
    docker logs --tail 15 stream-collector
    ```

3. Are the collectors writing events to the raw (good or bad) Kinesis streams?
    * You can look at the \[CloudWatch SnowPlow dashboard\](update link when ready), or go to the [Kinesis Data streams](https://us-east-2.console.aws.amazon.com/kinesis/home?region=us-east-2#/streams/list) service in AWS and look at the stream monitoring tabs.

## Not writing events out

1. First, make sure the collectors are working ok by looking over the steps above. It's possible that if nothing is getting collected, nothing is being written out.
1. In the \[CloudWatch SnowPlow dashboard\](update link when ready) dashboard, look at the **Stream Records Age** graph to see if a Kinesis stream is backing up. This graph shows the milliseconds that records are left in the streams and it should be zero most of the time. If there are lots of records backing up, the enrichers may not be picking up work, or Firehose is not writing records to S3. Reference the pipeline diagram above to help determine which broken part might cause a stream to have long-lived records in the stream.
1. Verify there are running enricher instances by checking the
  [SnowPlowEnricher](https://us-east-2.console.aws.amazon.com/ec2/home?region=us-east-2#AutoScalingGroups:) auto scaling group.
1. There is no current automated method to see if the enricher processes are running on the nodes. To check the logs, SSH into one of the enricher instances and then run:

    ```sh
    docker logs --tail 15 stream-enrich
    ```

1. Are the enricher nodes picking up events and writing them into the enriched Kinesis streams? Look for the [Kinesis stream](https://us-east-2.console.aws.amazon.com/kinesis/home?region=us-east-2#/streams/list) monitoring tabs.
1. Check that the [Kinesis Firehose](https://us-east-2.console.aws.amazon.com/firehose/home?region=us-east-2#/streams) monitoring for the enriched (good and bad) streams are processing events. You may want to turn on CloudWatch logging if you are stuck and can't seem to figure out what's wrong.
1. Check the [Lambda function](https://us-east-2.console.aws.amazon.com/lambda/home?region=us-east-2#/functions) that is used to process events in Firehose. There should be plenty of invocations at any time of day. A graph of invocations is on the [CloudWatch SnowPlow dashboard](https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=SnowPlow).

## SSH Access to nodes

You will need the `snowplow.pem` file from 1Password and you will connect to the nodes as the `ec2-user`.
