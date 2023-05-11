# Steps to Recreate/Rebuild a new Standby CLuster using a Snapshot from a Production cluster as Master cluster (instead of pg_basebackup)

The recreation of the Standby Clusters is done entirely locally through TF and Ansible

<!-- vscode-markdown-toc -->
* 1. [Pre-requisites](#Pre-requisites)
* 2. [Chef role for the Target cluster](#ChefrolefortheTargetcluster)
* 3. [Define the new Standby Cluster in Terraform](#DefinethenewStandbyClusterinTerraform)
* 4. [Steps to Destroy a Standby Cluster if you want to recreaate it](#StepstoDestroyaStandbyClusterifyouwanttorecreaateit)
* 5. [Create the Patroni CI Standby Cluster instances](#CreatethePatroniCIStandbyClusterinstances)
	* 5.1. [TF create](#TFcreate)
	* 5.2. [Stop patroni and reset WAL directory from old files](#StoppatroniandresetWALdirectoryfromoldfiles)
	* 5.3. [Initialize Patroni standby_cluster with Ansible playbook](#InitializePatronistandby_clusterwithAnsibleplaybook)

<!-- vscode-markdown-toc-config
	numbering=true
	autoSave=true
	/vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc -->

##  1. <a name='Pre-requisites'></a>Pre-requisites

1. Terraform should be installed and configured;
2. Ansible should be installed and configured into your account into your workstatation or a `console` node, you can use the following commands:
    ```
    python3 -m venv ansible
    source ansible/bin/activate
    python3 -m pip install --upgrade pip
    python3 -m pip install ansible
    ansible --version
    ```
3. Download/clone the [ops.gitlab.net/gitlab-com/gl-infra/config-mgmt](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt) project into your workstatation or a `console` node;

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

##  4. <a name='StepstoDestroyaStandbyClusterifyouwanttorecreaateit'></a>Steps to Destroy a Standby Cluster if you want to recreaate it 

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


##  5. <a name='CreatethePatroniCIStandbyClusterinstances'></a>Create the Patroni CI Standby Cluster instances

###  5.1. <a name='TFcreate'></a>TF create

If you are creating the nodes for the first time, they should be created by our CI/CO pipeline when you merge the changes in `main.tf` in the repository. Otherwise, if you have destroyed using `tf destroy` you can manually create them with:

```
cd /config-mgmt/environments/<environment>
tf destroy -target="module.<standby_cluster_tf_module>"
```

###  5.2. <a name='StoppatroniandresetWALdirectoryfromoldfiles'></a>Stop patroni and reset WAL directory from old files

Before executing the playbook to create the standby cluster, you have to stop patroni service in all nodes of the new standby cluster.

```
knife ssh "role:<patroni_standby_cluster_role>" "sudo systemctl stop patroni"
````

Then you have to clean out the `pg_wal` directory of in all nodes of the new standby cluster, otherwise there could be old TL history data on this directories that will affect the WAL recovery from the source cluster.
You can perform the following:

```
knife ssh "role:<patroni_standby_cluster_role>" "sudo rm -rf /var/opt/gitlab/postgresql/data12/pg_wal; sudo mkdir /var/opt/gitlab/postgresql/data12/pg_wal; sudo chown gitlab-psql /var/opt/gitlab/postgresql/data12/pg_wal"
```

Note: you can change `/var/opt/gitlab/postgresql/data12` to any other data directory that is in use, eg. `/var/opt/gitlab/postgresql/data14`, etc.


###  5.3. <a name='InitializePatronistandby_clusterwithAnsibleplaybook'></a>Initialize Patroni standby_cluster with Ansible playbook

1. Download/clone the [gitlab.com/gitlab-com/gl-infra/db-migration](https://gitlab.com/gitlab-com/gl-infra/db-migration) project into your workstatation or a `console` node;

```
git clone https://gitlab.com/gitlab-com/gl-infra/db-migration.git
```

2. Check that the inventory file for your desired environment exists in `db-migration/pg-replica-rebuild/inventory/` and it's up-to-date with the hosts you're targeting. The inventory file should contain
    - `all.vars.walg_gs_prefix`: this is the GCS bucket and directory of the SOURCE database WAL archive location (the source database is the cluster you refered the `data_disk_snapshot` to create the cluster throught TF). You can find this value in the source cluster Chef role, it shoud be the `gitlab_walg.storage_prefix` for that cluster.
    - `all.hosts`: a regex that represent the FQDN of the hosts that are going to be part of this cluster, where the first node will be created as Standby Leader.

Example:
        ```
        all:
        vars:
            walg_gs_prefix: 'gs://gitlab-gstg-postgres-backup/pitr-walg-main-pg12-2004'
        hosts:
            patroni-main-v14-[101:105]-db-gstg.c.gitlab-staging-1.internal:
        ```

3. Run `ansible -i inventory/<file> all -m ping` to ensure that all `hosts` in the inventory are reachable;

```
cd db-migration/pg-replica-rebuild
ansible -i inventory/<file> all -m ping
```

4. Execute the `rebuild-all` Ansible playbook to create the standby_cluster, and sync all nodes with the source database;

```
cd db-migration/pg-replica-rebuild
ansible-playbook -i inventory/patroni-main-v14-gstg.yml rebuild-all.yml
```
