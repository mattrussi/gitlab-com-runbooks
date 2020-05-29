# Pg_repack using gitlab-pgrepack

[gitlab-pgrepack](https://gitlab.com/gitlab-com/gl-infra/gitlab-pgrepack.git) is a helper tool for running pg_repack in Gitlab eenvironments.

## Prerequisites

- Request an auth token for Grafana annotations and modify `auth_key` accordingly.


## Setting up the tool

This tool runs in a local user environment fashion, as follows:

```

cd $HOME

gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB

curl -sSL https://get.rvm.io | bash -s stable --ruby

source ~/.rvm/scripts/rvm


git clone https://gitlab.com/gitlab-com/gl-infra/gitlab-pgrepack.git
cd gitlab-pgrepack
bundle update --bundler
bundle install 

cat > ~/gitlab-pgrepack/config/gitlab-repack.yml <<EOF
general:
  env: local
database:
  adapter: postgresql
  host: patroni-04-db-gstg.c.gitlab-staging-1.internal
  user: gitlab-superuser
  password: xxx
  database: gitlabhq_production
estimate:
  ratio_threshold: 0 # bloat ratio threshold in % (set to 0 for testing)
  real_size_threshold: 0 # real size of object in bytes (set to 0 for testing)
  objects_per_repack: 1
repack:
- command: PGPASSWORD=xxx pg_repack -h patroni-04-db-gstg.c.gitlab-staging-1.internal -p 5432 -U gitlab-superuser -d gitlabhq_production --no-kill-backend

# Optional: Grafana annotations
grafana:
  auth_key: false # put API key here to enable
  base_url: https://dashboards.gitlab.net
EOF


sudo su - gitlab-psql -c 'gitlab-psql -c "ALTER SYSTEM SET max_wal_size TO '''\'8GB\'''';"'
sudo su - gitlab-psql -c 'gitlab-psql -c "ALTER SYSTEM SET maintenance_work_mem TO '''\'2GB\''''; select pg_reload_conf()"'

```

## Get objects that need unbloat

The bellow command, outputs both tables and indexes that require repack:

```
bin/gitlab-pgrepack estimate
```

Copy these statements to place them in the script bellow.


## Script


- Open a `tmux` session before running this script.

```
#!/bin/bash
# https://gitlab.com/gitlab-com/gl-infra/production/issues/1391

# Not tested yet

#set -e                                                                                                                                                              
_WAL_SIZE_ORI=$(sudo gitlab-psql -tc 'SHOW max_wal_size')
_MAINTENANCE_WM_ORI=$(sudo gitlab-psql -tc 'SHOW maintenance_work_mem')
_DATETIME=$(date +'%F %T')
_LOGFILE=/var/tmp/repack.out

#Func
index_size() {
        _INDEX_SIZE=$(sudo gitlab-psql -tc "select pg_size_pretty(pg_relation_size('$_INDEX_NAME'))")
        echo -e "$_DATETIME\tIndex size: $_INDEX_SIZE" >> $_LOGFILE
}

pre_alter() {
# Could not found the way to control the command exit code yet
# If the ALTER SYSTEM fails (i.e wrong var name) the reload is executed anyway.
# Be careful and control script output
sudo gitlab-psql <<EOF
ALTER SYSTEM SET max_wal_size TO '6GB';
SELECT pg_reload_conf();
EOF

echo -e "$(date +'%F %T')\tmax_wal_size changed" >> $_LOGFILE

sudo gitlab-psql <<EOF
ALTER SYSTEM SET maintenance_work_mem TO '20GB';
SELECT pg_reload_conf();
EOF
 
echo -e "$(date +'%F %T')\tmaintenance_work_mem changed" >> $_LOGFILE
}

post_alter() {

sudo gitlab-psql <<EOF
ALTER SYSTEM SET maintenance_work_mem TO '${_MAINTENANCE_WM_ORI}';
SELECT pg_reload_conf();
EOF

echo -e "$(date +'%F %T')\tmaintenance_work_mem successfuly restored" >> $_LOGFILE

sudo gitlab-psql <<EOF
ALTER SYSTEM SET max_wal_size TO '${_WAL_SIZE_ORI}';
SELECT pg_reload_conf();
EOF

echo -e "$(date +'%F %T')\tmax_wal_size successfuly restored" >> $_LOGFILE
}

# Backup original values
echo -e "$(date +'%F %T')\tBackup original variables values:" >> $_LOGFILE
sudo gitlab-psql -c 'SHOW max_wal_size' -o /var/tmp/max_wal_size.ori
sudo gitlab-psql -c 'SHOW maintenance_work_mem' -o /var/tmp/maintenance_work_mem.ori
echo -e "$(date +'%F %T')\tLook at /var/tmp/max_wal_size.ori and /var/tmp/maintenance_work_mem.ori" >> $_LOGFILE
echo -e "$(date +'%F %T')\tBackup done, start alter" >> $_LOGFILE

pre_alter || echo -e "$_DATETIME\tAn error ocurren when ALTER SYSTEM ran" >> $_LOGFILE

(
# Add here the gitlab_pgrepack command
) >> $_LOGFILE

post_alter || echo -e "$_DATETIME\tThere was an error restoring the original values" >> $_LOGFILE

echo -e "$_DATETIME\tEnd script" >> $_LOGFILE#!/bin/bash
# https://gitlab.com/gitlab-com/gl-infra/production/issues/1391

# Not tested yet

#set -e                                                                                                                                                              
_WAL_SIZE_ORI=$(sudo gitlab-psql -tc 'SHOW max_wal_size')
_MAINTENANCE_WM_ORI=$(sudo gitlab-psql -tc 'SHOW maintenance_work_mem')
_DATETIME=$(date +'%F %T')
_LOGFILE=/var/tmp/repack.out

#Func
index_size() {
        _INDEX_SIZE=$(sudo gitlab-psql -tc "select pg_size_pretty(pg_relation_size('$_INDEX_NAME'))")
        echo -e "$_DATETIME\tIndex size: $_INDEX_SIZE" >> $_LOGFILE
}

pre_alter() {
# Could not found the way to control the command exit code yet
# If the ALTER SYSTEM fails (i.e wrong var name) the reload is executed anyway.
# Be careful and control script output
sudo gitlab-psql <<EOF
ALTER SYSTEM SET max_wal_size TO '6GB';
SELECT pg_reload_conf();
EOF

echo -e "$(date +'%F %T')\tmax_wal_size changed" >> $_LOGFILE

sudo gitlab-psql <<EOF
ALTER SYSTEM SET maintenance_work_mem TO '20GB';
SELECT pg_reload_conf();
EOF
 
echo -e "$(date +'%F %T')\tmaintenance_work_mem changed" >> $_LOGFILE
}

post_alter() {

sudo gitlab-psql <<EOF
ALTER SYSTEM SET maintenance_work_mem TO '${_MAINTENANCE_WM_ORI}';
SELECT pg_reload_conf();
EOF

echo -e "$(date +'%F %T')\tmaintenance_work_mem successfuly restored" >> $_LOGFILE

sudo gitlab-psql <<EOF
ALTER SYSTEM SET max_wal_size TO '${_WAL_SIZE_ORI}';
SELECT pg_reload_conf();
EOF

echo -e "$(date +'%F %T')\tmax_wal_size successfuly restored" >> $_LOGFILE
}

# Backup original values
echo -e "$(date +'%F %T')\tBackup original variables values:" >> $_LOGFILE
sudo gitlab-psql -c 'SHOW max_wal_size' -o /var/tmp/max_wal_size.ori
sudo gitlab-psql -c 'SHOW maintenance_work_mem' -o /var/tmp/maintenance_work_mem.ori
echo -e "$(date +'%F %T')\tLook at /var/tmp/max_wal_size.ori and /var/tmp/maintenance_work_mem.ori" >> $_LOGFILE
echo -e "$(date +'%F %T')\tBackup done, start alter" >> $_LOGFILE

pre_alter || echo -e "$_DATETIME\tAn error ocurren when ALTER SYSTEM ran" >> $_LOGFILE

(

# Add here the gitlab_pgrepack command

) >> $_LOGFILE

post_alter || echo -e "$_DATETIME\tThere was an error restoring the original values" >> $_LOGFILE

echo -e "$_DATETIME\tEnd script" >> $_LOGFILE
```



