# How to change Runner Manager's instance specification

Our [Runner Managers](README.md#runner-descriptions) are running in GCP instances. Sometimes
it's required to change the specification of these instances, for example add more CPU, memory,
disk space.

As modifying instance specification is an operation that in GCP can be done only when this instance
is stopped, we need to carefully follow a procedure including
[Graceful Shutdown](linux/graceful-shutdown.md). To be precise, we need to follow
the [How to stop or restart Runner Manager's VM with Graceful Shutdown procedure](linux/graceful-shutdown.md#how-to-stop-or-restart-runner-managers-vm-with-graceful-shutdown).

## Preflight checklist

Before you will start any work

1. [ ] Make sure that you meet [Administrator prerequisites](linux/README.md#administrator-prerequisites) before you will
   start any work.
1. [ ] You have access to GCP console, to the `gitlab-ci` project.
1. [ ] [Not in a PCL time window](README.md#production-change-lock-pcl).
1. [ ] [Change Management](https://about.gitlab.com/handbook/engineering/infrastructure/change-management/) issue was
   created for this configuration change.

> **Notice:** As it's described in the Graceful Shutdown procedure description
> [we can shutdown only one runner of a specific type](linux/graceful-shutdown.md#graceful-shutdown-and-different-runner-manager-types-srm-gsrm-prm-gdsrm-etc)
> at once!

## Procedure

1. [Choose](https://console.cloud.google.com/compute/instances?project=gitlab-ci-155816&instancessize=50&instancesquery=%255B%257B_22k_22_3A_22labels_22_2C_22t_22_3A10_2C_22v_22_3A_22_5C_22gl_resource_type_3Aci_manager_5C_22_22%257D%255D)
   which node requires the instance specification change.

1. Follow [How to stop or restart Runner Manager's VM with Graceful Shutdown procedure](linux/graceful-shutdown.md#how-to-stop-or-restart-runner-managers-vm-with-graceful-shutdown),
   the _If you want to stop the VM_ path, until the _Do whatever you needed to do with Runner's VM terminated_ step.

1. When the instance is stopped:

    - for `srmX`, `gsrmX` and `prmX` managers: go to GCP console, the `gitlab-ci` project, and change the specification,
    - for `gdsrmX` we're currently working on a solution, as the configuration of the infrastructure is managed
        by terraform and this makes it problematic to handle hosts 1-by-1 as it's needed in this case.

1. When the specification of the VM is updated go back to the
   [How to stop or restart Runner Manager's VM with Graceful Shutdown procedure](linux/graceful-shutdown.md#how-to-stop-or-restart-runner-managers-vm-with-graceful-shutdown)
   and continue until it's fully done.

1. Repeat the steps for another Runner Manager node if needed.
