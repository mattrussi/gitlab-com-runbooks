# MacOS resources in AWS

This document outlines where most of the resources live in AWS, this can help you know where to look to debug issues.

Go to [access.md](./access.md) for information on how to access the resources described in this document.

## EC2

[console.aws.amazon.com/ec2](https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1)

### Instances

- All the VMs found here are in `us-east-1` region.
- All the VMs are considered _ephemeral VMs_.
    - These are short lived VMs, in the case of MacOS, they live for _at least_ 24h.
    - The 24h rule is due to licensing limitations, see [licensing.md](./licensing.md) for details.
- There are firewall rules between AWS and GCP (`gitlab-ci-155816` project) to allow `ssh` and other traffic from these VMs.
- See [architecture.md](./architecture.md) for more details about the connections established between AWS and GCP.

### Dedicated Hosts

- Perhaps the most important column in this view is the `State` of each of the Hosts.
- When a host is missing `vCPU utilization` info, it could indicate the instance is deleted, but not yet deleted from the account's pool.
- _Released_ state means the instance is no longer connected to our AWS account, it's not clear how long it takes for these entries to be deleted.
- _Pending_ indicates the instance is currently being provisioned.

### AMIs

The images appearing in the AMI view have two purposes:

- images for the EC2 instances
- images for the user facing jobs*

NOTE: *To understand the difference between these two images, you should have a basic understanding of the architecutre of these runners.
In a nutshell, each EC2 VM you see in the console, spins up two **nested VMs** within itself.
These nested VMs use the `user facing jobs` images, while the parent VM, uses the EC2 instance images.
For more details on the architecture of these runners, have a look at [architecture.md](./architecture.md).

### Volumes and Snapshots

### Security Groups

### Network Interfaces

### Auto Scaling Groups


## Service Quotas

[console.aws.amazon.com/servicequotas](https://us-east-1.console.aws.amazon.com/servicequotas/home?region=us-east-1#)

Quota limits for how many _dedicated_ Mac VMs we can run at a time. To view these limits:

- Go to _Amazon Elastic Compute Cloud (Amazon EC2)_.
- Filter for `mac2`.
- Click _Running Dedicated mac2 Hosts_.

For Staging, the limits at the time of this writing are `8` machines, while for Production, the limits are `20`.


## Elastic container registery

[console.aws.amazon.com/repositories](https://us-east-1.console.aws.amazon.com/ecr/repositories?region=us-east-1)

- This is where the images used by [nesting](./architecture.md#nesting) are stored.
- These are big images, about 50GBs each. Pulling that everytime a user requests a VM would take nearly 30 minutes, which is not an acceptable queuing time. _Nesting_ was introduced to solve this problem; by pre-downloading two images (maxmimum disk capacity) in the Parent VM, which then become available for end users to use, and takes just under 15 seconds to pick a new job, and another 15 seconds to re-cycle before it's ready for another job.
- NOTE: These images live in the Staging environment only, but can be pulled from the Production environment.



## S3

[console.aws.amazon.com/s3](https://s3.console.aws.amazon.com/s3/home?region=us-east-1)

## VPC

[console.aws.amazon.com/vpc](https://us-east-1.console.aws.amazon.com/vpcconsole/home?region=us-east-1#Home:)

### Route table

### Security groups

### Subnets

## IAM

[console.aws.amazon.com/iam](https://us-east-1.console.aws.amazon.com/iamv2/home?region=us-east-1#/home)
