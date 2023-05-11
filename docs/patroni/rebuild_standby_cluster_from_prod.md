# Steps to Recreate/Rebuild a new Standby CLuster using a Snapshot from a Production cluster as Master cluster (instead of pg_basebackup)

The recreation of the Standby Clusters is done entirely locally through TF and Ansible

<!-- vscode-markdown-toc -->
* 1. [Pre-requisites](#Pre-requisites)
* 2. [Chef role for the Target cluster](#ChefrolefortheTargetcluster)
* 3. [Define the new Standby Cluster in Terraform](#DefinethenewStandbyClusterinTerraform)
* 4. [Create the Patroni CI Standby Cluster instances](#CreatethePatroniCIStandbyClusterinstances)
* 5. [Destroy the Standby Cluster (if it already exist)](#DestroytheStandbyClusterifitalreadyexist)

<!-- vscode-markdown-toc-config
	numbering=true
	autoSave=true
	/vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc -->

##  1. <a name='Pre-requisites'></a>Pre-requisites

1. Terraform should be installed and configured;
2. Ansible should be installed and configured into your account into a `console` node, you can use the following commands:
    ```
    python3 -m venv ansible
    source ansible/bin/activate
    python3 -m pip install --upgrade pip
    python3 -m pip install ansible
    ansible --version
    ```
3. Download/clone the [ops.gitlab.net/gitlab-com/gl-infra/config-mgmt](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt) project into a `console` node;
4. Download/clone the [gitlab.com/gitlab-com/gl-infra/db-migration](https://gitlab.com/gitlab-com/gl-infra/db-migration) project into a `console` node;
5. Check that the inventory file for your desired environment exists in `db-migration/pg-replica-rebuild/inventory/` and it's up-to-date with the hosts you're targeting;
6. Run `cd db-migration/pg-replica-rebuild; ansible -i inventory/<file> all -m ping` and ensure that all nodes are reachable;


##  2. <a name='ChefrolefortheTargetcluster'></a>Chef role for the Target cluster

Some `postgresql` settings need to be the SAME as the Source cluster for the physical replication to work, they are:

```
    "postgresql": {
        "version":
        "pg_user_homedir":
        "config_directory":
        "data_directory":
        "log_directory":
        "bin_directory":
    ...
    }

```

**IMPORTANT: the `gitlab_walg.storage_prefix` in the target Chef role SHOULD NOT BE THE SAME as the Source cluster**, otherwise the backup of the source cluster can be overwriten.

The Chef role of the standby patroni cluster should have defined the `standby_cluster` settings under `override_attributes.gitlab-patroni.patroni.config.bootstrap.dcs` like the bellow example.
Notice that `host` should point to the endpoint of the Primary/Master node of the source cluster, therefore if there's a failover we don't have to reconfigure the standby cluster.

```
  "override_attributes": {
    "gitlab-patroni": {
      "patroni": {
        "config": {
          "bootstrap": {
            "dcs": {
              "standby_cluster": {
                "host": "master.patroni.service.consul",
                "port": 5432
              }
            }
          }
        }
      }
    }
  },
```

##  3. <a name='DefinethenewStandbyClusterinTerraform'></a>Define the new Standby Cluster in Terraform

Define a disk snapshot from the source cluster in Terraform, like for example:

```
data "google_compute_snapshot" "gcp_database_snapshot_gprd_main_2004" {
  filter      = "sourceDisk eq .*/patroni-main-2004-.*"
  most_recent = true
}
```

When defining the target cluster module in Terraform, define the storage size and settings similar as the source, and then define the `data_disk_snapshot` pointing to the source snapshot and a large amount of time for `data_disk_create_timeout`, like for example:

```
module "patroni-main-standby_cluster" {
  source  = "ops.gitlab.net/gitlab-com/generic-stor-with-group/google"
  version = "8.1.0"

  data_disk_size           = var.data_disk_sizes["patroni-main-2004"]
  data_disk_type           = "pd-ssd"
  data_disk_snapshot       = data.google_compute_snapshot.gcp_database_snapshot_gprd_main_2004.id
  data_disk_create_timeout = "120m"
  ...
}
```

##  5. <a name='DestroytheStandbyClusterifitalreadyexist'></a>Steps to Destroy a Standby Cluster if you want to recreaate it 

Perform a TF destroy locally using target

```
cd /config-mgmt/environments/<environment>
tf destroy -target="module.<standby_cluster_tf_module>"
```

Clean out any remaining Chef client/nodes using `knife`, like for example:

```
knife node delete --yes patroni-main-standby_cluster-10{1..5}-db-$env.c.gitlab-$gcp_project.internal
knife client delete --yes patroni-main-standby_cluster-10{1..5}-db-$env.c.gitlab-$gcp_project.internal
```


##  4. <a name='CreatethePatroniCIStandbyClusterinstances'></a>Create the Patroni CI Standby Cluster instances

You can use the following steps to create all or a subset of the patroni CI instances, just depending on how many instances were previously destroyed.

1. Change Terraform environment
    - Execute the following `gcloud` command to get the name of the most recent GCS snapshot from the patroni backup data disk, but **DO NOT SIMPLY COPY/PASTE IT**, set the `--project` and `--filter` accordingly with the environment you are performing the restore:

        ```
        gcloud compute snapshots list --project [gitlab-staging-1|gitlab-production] --limit=1 --uri --sort-by=~creationTimestamp --filter=status~READY --filter=sourceDisk~patroni-[06-db-gstg|v12-10-db-gprd]-data
        ```

    - Remove the `https://www.googleapis.com/compute/v1/` prefix of the snapshot name

        - For example: `https://www.googleapis.com/compute/v1/projects/gitlab-production/global/snapshots/nukw46z00o90` will turn into `projects/gitlab-production/global/snapshots/nukw46z00o90`

    - Add the following line into `patroni-ci` module at `main.tf`

        ```
          data_disk_snapshot     = "<snapshot_name>"
          data_disk_create_timeout = "120m"
        ```

    - Change the `"node_count"` of patroni CI back to the original amount of nodes at `variables.tf`:

        <details><summary>Node count in GSTG</summary>

        ```
            "patroni-ci"           = 7
        ```

        </details>
        <details><summary>Node count in GPRD</summary>

        ```
            "patroni-ci"           = 10
        ```

        </details>

1. Create all the Patroni CI nodes with: `tf apply`
1. Check the VM instance Serial port in the GCP console to see if the instance is already initialized and if Chef has finished running, for example:
   - GSTG: instance [patroni-ci-01-db-gstg/console?port=1&project=gitlab-staging-1](https://console.cloud.google.com/compute/instancesDetail/zones/us-east1-c/instances/patroni-ci-01-db-gstg/console?port=1&project=gitlab-staging-1)
   - GPRD: instance [patroni-ci-01-db-gprd/console?port=1&project=gitlab-production](https://console.cloud.google.com/compute/instancesDetail/zones/us-east1-c/instances/patroni-ci-01-db-gprd/console?port=1&project=gitlab-production)
   - Or you can execute `gcloud compute instances get-serial-port-output <instance_name>`
1. Look into the instance Serial Console, or `/var/log/syslog` log file, if the Chef bootstrap has failed. Any kind of error needs to be addressed, except for while performing `usermod: directory /var/opt/gitlab/postgresql`, which is a known issue that can be ignored. Therefore if you observe the following message in `/var/log/syslog` or the instance serial port/console, you can start executing the pg-replica-rebuild Ansible playbook.

    ```
    $ sudo cat /var/log/syslog | grep "STDERR: usermod: directory /var/opt/gitlab/postgresql exists"

    ??? ??? GCEMetadataScripts[1935]: ??? GCEMetadataScripts: startup-script: #033[0m    STDERR: usermod: directory /var/opt/gitlab/postgresql exists
    ??? ??? GCEMetadataScripts[1935]: ??? GCEMetadataScripts: startup-script: STDERR: usermod: directory /var/opt/gitlab/postgresql exists
    ```

1. **If Chef failed for any other reason**, then you might have to:
    - Manually delete the nodes from Chef
        <details><summary>Knife node delete GSTG</summary>

        ```
        for i in `seq 7`; do for type in node client; do knife $type delete -y patroni-ci-$(printf '%02d' $i)-db-gstg.c.gitlab-staging-1.internal; done; done
        ````

        </details>
        <details><summary>Knife node delete GPRD</summary>

        ```
        for i in `seq 10`; do for type in node client; do knife $type delete -y patroni-ci-$(printf '%02d' $i)-db-gprd.c.gitlab-production.internal; done; done
        ````

        </details>
    - Restart the VM instances through the GCP console

1. From a `console` node initialize a Tmux session to execute the Ansible playbook from it;

1. Execute the `db-migration/pg-replica-rebuild` Ansible playbook from your Tmux session to Initialize the whole cluster or a set of Replicas:

    - To initialize the whole cluster, including the Standby Leader, run the `rebuild-all.yml` playbook:

        ```
        cd <workspace>/db-migration/pg-replica-rebuild
        ansible-playbook -i inventory/<environment_file>.yml rebuild-all.yml
        ```

    - To initialize only  Replicas in the cluster, run the `rebuild-replicas.yml` playbook using [Ansible's `-l <SUBSET>`](https://docs.ansible.com/ansible/latest/cli/ansible-playbook.html#cmdoption-ansible-playbook-l) and [patterns to target hosts and groups](https://docs.ansible.com/ansible/latest/user_guide/intro_patterns.html#patterns-targeting-hosts-and-groups), limiting the replica hosts where the playbook will be executed, like for example:

        - For example, to initialize all replicas except node `patroni-ci-01` you can use the following pattern regex:

            ```
            cd <workspace>/db-migration/pg-replica-rebuild
            ansible-playbook -i inventory/<environment_file>.yml rebuild-replicas.yml -l '!~patroni-ci-01'
            ```

        - For example, to initialize the range of 4 replicas starting from `patroni-ci-06` up to `patroni-ci-10` you can use the following pattern regex:

            ```
            cd <workspace>/db-migration/pg-replica-rebuild
            ansible-playbook -i inventory/<environment_file>.yml rebuild-replicas.yml -l '~patroni-ci-(0[6-9]|10)'
            ```

1. Force run of Chef-Client in the nodes to let all configuration files in sync with the repo
    <details><summary>Force run of Chef-Client in GSTG</summary>

    ```
    knife ssh -C 7 "role:gstg-base-db-patroni-ci" "sudo chef-client"
    ```

    </details>
    <details><summary>Force run of Chef-Client in GPRD</summary>

    ```
    knife ssh -C 10 "role:gprd-base-db-patroni-ci" "sudo chef-client"
    ```

    </details>



