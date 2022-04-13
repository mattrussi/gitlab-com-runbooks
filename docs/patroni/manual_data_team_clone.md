# Making a manual clone of the DB for the data team

This page has information for making a manual clone of the database for the data team.
It was a process created in April 2022 related to [Reliability/15565](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/15565)
and is based on the notes from [Reliability](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/15574).

This machine currently needs to be remade daily and available by 00:00 UTC each day.
The steps should take a total of roughly 1-2 hours though most of that time is waiting.  The recreation of the VM should take ~30 min in Terraform.

Once things are complete, we have been commenting in Slack in #data-team-temp-database and on [issue 15574](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/15574) 

## How to recreate VM from the latest snapshot:


First in Terraform:
```
tf destroy --target="module.patroni-data-analytics"
tf apply --target="module.patroni-data-analytics"
```

Note that there should be 10 items to be destroyed and rebuilt.
<sample output> to show what is okay.

## Procedure to reconfigure the `patroni-data-analytics` cluster after recreating the VM:

1. Stop the Patroni service in the nodes with the command: `sudo systemctl stop patroni`
2. Get the cluster name: `sudo gitlab-patronictl list`
3. Remove the DCS entry from the cluster, executing : `sudo gitlab-patronictl remove patroni-data-analytics`
Answer the name of the cluster that will be removed: `patroni-data-analytics`
Answer the confirmation message: `Yes I am aware`
4. Change the ownership from the data and log folders in all cluster nodes:
```
sudo su -
cd /var/opt/gitlab/
chown -R gitlab-psql:gitlab-psql postgresql/
chown -R gitlab-psql:gitlab-psql patroni/
cd /var/log/gitlab/
chown -R gitlab-psql:gitlab-psql postgresql/
chown -R syslog:syslog patroni/
```
5 - Delete recovery.conf config file if exists, for all nodes in all clusters:
```
sudo rm -rf /var/opt/gitlab/postgresql/data12/recovery.conf
```
6 - Start Patroni:
```
sudo systemctl start patroni
```
7 - Monitor the patroni status and wait until the node is ready:
```
watch -n 1 sudo gitlab-patronictl list
```
