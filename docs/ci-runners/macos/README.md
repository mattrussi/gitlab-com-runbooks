# MacOS Runners

## Overview

All of the MacOS runners are hosted in AWS.

## Access to MacOS VMs

To access MacOS VMs in AWS:

- **Production Environment**: All SREs have default access through Okta. Navigate to `AWS Services Org` and select `saas-mac-runners-b6fd8d28` in the Okta dashboard. The primary region for these resources is `N. Virginia` (`us-east-1`).

- **Staging/Production via GitLab Sandbox**: For those with the appropriate access, the staging environment can be accessed through specific steps in the GitLab sandbox.

For step-by-step access procedures, refer to the [Accessing MacOS VMs section](./access.md#accessing-macos-vms).

## AWS Resources

Key AWS resources related to MacOS runners include:

- **EC2 Instances**: Ephemeral VMs with specific firewall rules and dedicated hosts. Details about AMIs and architecture can be found in [EC2 Instances](./resources.md#ec2).

- **Service Quotas**: Information about the limitations for running dedicated Mac VMs is detailed in [Service Quotas](./resources.md#service-quotas).

- **Elastic Container Registry**: Holds images for nested VMs, aiming to reduce image size and queuing time. Further details are in [Elastic Container Registry](./resources.md#elastic-container-registery).

- **Additional Resources**: S3, VPC, and IAM are also utilized and are briefly described in [Additional AWS Components](./resources.md#s3-vpc-iam).

## Additional Information

For more detailed information about the resources and access methods:

- [Accessing AWS Resources](./access.md): Comprehensive guide on accessing MacOS VMs in different environments.

- [MacOS AWS Resources](./resources.md): In-depth details on the AWS resources used, including EC2, service quotas, and more.
