### MacOS resources in AWS

This document outlines where most of the resources live in AWS, this can help you know where to look to debug issues.

Go to [access.md](./access.md) for information on how to access the resources described in this document.

#### EC2

- All the VMs found here are in `us-east-1` region.
- All the VMs are considered _ephemeral VMs_.
    - These are short lived VMs, in the case of MacOS, they live for _at least_ 24h.
    - The 24h rule is due to licensing limitations, see [licensing.md](./licensing.md) for details.
- There are firewall rules between AWS and GCP (`gitlab-ci-155816` project) to allow `ssh` and other traffic from these VMs.
- See [architecture.md](./architecture.md) for more details about the connections established between AWS and GCP.

#### Service Quotas

There are quota limits set for how many _dedicated_ Mac VMs we can run at a time. To view these limits:

- https://us-east-1.console.aws.amazon.com/servicequotas/home?region=us-east-1#
- Go to _Amazon Elastic Compute Cloud (Amazon EC2)_.
- Filter for `mac2`.
- Click _Running Dedicated mac2 Hosts_.

For Staging, the limits at the time of this writing are `8` machines, while for Production, the limits are `20`.

#### AMI

The images appearing in the AMI view have two purposes:

- images for the EC2 instances
- images for the user facing jobs*

NOTE: *To understand the difference between these two images, you should have a basic understanding of the architecutre of these runners.
In a nutshell, each EC2 VM you see in the console, spins up two **nested VMs** within itself.
These nested VMs use the `user facing jobs` images, while the parent VM, uses the EC2 instance images.
For more details on the architecture of these runners, have a look at [architecture.md](./architecture.md).

#### Elastic container registery

#### Volumes and snapshots

#### Network

#### Security groups

#### Auto scaling groups

#### Dedicated Hosts view

#### S3

#### Routing table

#### IAM view
