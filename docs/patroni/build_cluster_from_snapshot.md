# Steps to Create a Standby Patroni CLuster using a Snapshot from the Primary cluster (instead of pg_basebackup)

Create a new Patroni Standby Cluster based on a recent snapshot from a node of the Primary Patroni cluster.

## Pre-requisites

1. Ansible should be installed and configured into your account into a `console` node, you can use the following commands:

    ```
    python3 -m venv ansible
    source ansible/bin/activate
    python3 -m pip install --upgrade pip
    python3 -m pip install ansible
    ansible --version
    ```

1. Download/clone the [gitlab.com/gitlab-com/gl-infra/db-migration](https://gitlab.com/gitlab-com/gl-infra/db-migration) project into a `console` node;

## Create the Patroni Standby Cluster instances

You can use the following steps to create all or a subset of the patroni CI instances, just depending on how many instances were previously destroyed.

1. Create a new Terraform module on the environment where the new cluster is being created. Remember to set the corresponding variables.

* For example [gstg patroni-main-2004](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/master/environments/gstg/main.tf#L1035-1074)

1. Define the snapshot to be used by the new Standby Cluster:
    * Execute the following `gcloud` command to get the name of the most recent GCS snapshot from the patroni backup data disk, but **DO NOT SIMPLY COPY/PASTE IT**, set the `--project` and `--filter` accordingly with the environment you are performing the restore:

        ```
        gcloud compute snapshots list --project [gitlab-staging-1|gitlab-production] --limit=1 --uri --sort-by=~creationTimestamp --filter=status~READY --filter=sourceDisk~patroni-[06-db-gstg|v12-10-db-gprd]-data
        ```

    * Remove the `https://www.googleapis.com/compute/v1/` prefix of the snapshot name

        * For example: `https://www.googleapis.com/compute/v1/projects/gitlab-production/global/snapshots/nukw46z00o90` will turn into `projects/gitlab-production/global/snapshots/nukw46z00o90`

    * Add the following lines to the new Terraform module at `main.tf`

        ```
          data_disk_snapshot     = "<snapshot_name>"
          data_disk_create_timeout = "120m"
        ```

1. Commit your changes, merge and Apply to create the new cluster instances based on the latest snapshot.
1. Wait for Chef to complete running on the instances. You can tail the serial console logs as follows:

```
gcloud compute instances tail-serial-port-output <instance_name>
```

1. From a `console` node initialize a Tmux session to execute the Ansible playbook from it;
1. Check that the inventory file for your desired environment exists in `db-migration/pg-replica-rebuild/inventory/` and it's up-to-date with the hosts you're targeting;
1. Ensure that all nodes are reachable;

```
cd db-migration/pg-replica-rebuild; ansible -i inventory/<file> all -m ping
```

1. Execute the `db-migration/pg-replica-rebuild` Ansible playbook from your Tmux session to Initialize the whole cluster or a set of Replicas:

    * To initialize the whole cluster, including the Standby Leader, run the `rebuild-all.yml` playbook:

        ```
        cd <workspace>/db-migration/pg-replica-rebuild
        ansible-playbook -i inventory/<environment_file>.yml rebuild-all.yml
        ```

    * To initialize only  Replicas in the cluster, run the `rebuild-replicas.yml` playbook using [Ansible's `-l <SUBSET>`](https://docs.ansible.com/ansible/latest/cli/ansible-playbook.html#cmdoption-ansible-playbook-l) and [patterns to target hosts and groups](https://docs.ansible.com/ansible/latest/user_guide/intro_patterns.html#patterns-targeting-hosts-and-groups), limiting the replica hosts where the playbook will be executed, like for example:

        * For example, to initialize all replicas except node `patroni-XX-01` you can use the following pattern regex:

            ```
            cd <workspace>/db-migration/pg-replica-rebuild
            ansible-playbook -i inventory/<environment_file>.yml rebuild-replicas.yml -l '!~patroni-XX-01'
            ```

        * For example, to initialize the range of 4 replicas starting from `patroni-XX-06` up to `patroni-XX-10` you can use the following pattern regex:

            ```
            cd <workspace>/db-migration/pg-replica-rebuild
            ansible-playbook -i inventory/<environment_file>.yml rebuild-replicas.yml -l '~patroni-XX-(0[6-9]|10)'
            ```

1. Force run of Chef-Client in the nodes to let all configuration files in sync with the repo:
   <details><summary>Force run of Chef-Client in GPRD</summary>

    ```
    knife ssh -C 10 "role:gprd-base-db-patroni-XX" "sudo chef-client"
    ```

    </details>
