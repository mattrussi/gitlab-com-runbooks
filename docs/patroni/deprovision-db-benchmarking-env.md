# How and when to deprovision the db-benchmarking environment

# Introduction

From time to time we create Patroni cluster(s) in the `db-benchmarking` environment, with or without, using data disk snapshot of `gstg` or `gprd`. We understand the need to provision and use GCP resources in the `db-benchmarking` environment for a project/task but we want to be frugal and control the cost associated with such transient GCP resources. 

Our desire is to have automation to deprovision unused GCP resources based on TTL. We want to automate the deprovisioning of unused GCP resources based on TTL. But for now, the DBRE team will use a manual procedure for it.

We want automation to deprovision GCP resources according to TTL. While we are awaiting the automation, as a stop-gap solution, the DBRE team will use a manual procedure for it.

This runbook describes the procedure the DBRE team uses to deprovision the GCP resource (VMs, disk storage, disk snapshots etc.) in the `db-benchmarking` environment. 


### Guidelines for deprovisioning GCP resources in the db-benchmarking environment

- Shutdown the VM if the VM is not being used for more than 24 hours. Storage will still incur changes when the VM is shutdown.
- Destroy and deprovision VM and all the associated resources including the storage if the VM is stopped for more than 7 days. We use Terraform to manage our infrastructure - Config Management [repo link](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt) 


### How do we enforce deprovisioning GCP resources in the db-benchmarking environment?
- 