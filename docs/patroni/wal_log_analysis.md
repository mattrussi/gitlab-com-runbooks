
# WAL logs analysis

Analysis of write-ahead log of a PostgreSQL database cluster can be performed using the `pg_waldump` tool, however there are considerations on how to safely use `pg_waldump` with production data.

Security Compliance guideline regarding WAL analysis:
- **IMPORTANT: you should NEVER download WAL files into your personal workstation**
- WAL data contain users transactions, hence might contain **red data**
- Production **red data** should only be handled only within controled environments that follow Gitlab's Security Compliance
- Users should be granted least privilege access to Gitlab.com production (`gprd` gcp project) environment.
- If a user doesn't have have access to `gprd` it might request download of WAL files for debug/troubleshooting purposes into a node in the `db-benchmarking` environment.

## How to Fetch WALs from a Production environment into a working VM in the db-benchmarking environment

This is the procedure to fetech WALs from a GPRD database into a postgres VM in the db-benchmarking environment

### 1. Have wal-g installed on the VM by assigning the `gitlab_walg::default` recipie to the proper Chef role,

- Create the VM or run chef-client on the node to apply the recipie

### 2. Once wal-g is installed, manually configure the GPRD the gcs settings and credentials on it:

- As `root` create a `/etc/wal-g.d/env-gprd` directory with the same content of `/etc/wal-g.d/env`

  ```
  mkdir /etc/wal-g.d/env-gprd/
  cp /etc/wal-g.d/env/* /etc/wal-g.d/env-gprd/
  ```

- Edit `/etc/wal-g.d/env-gprd/WALG_GS_PREFIX` with the content from the GPRD environment (copy from a GPRD server)
- Edit `/etc/wal-g.d/env/GOOGLE_APPLICATION_CREDENTIALS` to point to `/etc/wal-g.d/gcs-gprd.json`
- Define the GPRD GCS credentials in the `/etc/wal-g.d/gcs-gprd.json` file (copy from a GPRD server)
- Change ownwership of the new GPRD env and credential files (IMPORTANT, DON'T SKIP THIS STEP)

  ```
  chown gitlab-psql /etc/wal-g.d/env-gprd/*
  chmod 600 /etc/wal-g.d/env-gprd/*
  chown gitlab-psql /etc/wal-g.d/gcs-gprd.json
  chmod 600 /etc/wal-g.d/gcs-gprd.json
  ```

- Create the `/var/opt/gitlab/wal_restore` directory

  ```
  mkdir /var/opt/gitlab/wal_restore
  chown gitlab-psql.gitlab-psql /var/opt/gitlab/wal_restore
  chmod 770 /var/opt/gitlab/wal_restore
  ```

### 3. Download/install the following script in the VM:

- https://gitlab.com/gitlab-com/gl-infra/db-migration/-/blob/master/bin/fetch_last_wals_from_gcs_into_dir.sh

### 4. Run the `fetch_last_wals_from_gcs_into_dir.sh` script as gitlab-psql:

```
sudo su - gitlab-psql
cd /var/opt/gitlab/wal_restore
/usr/local/bin/fetch_last_wals_from_gcs_into_dir.sh
```

### 5. Include the requestor user into the `gitlab-psql` group to grant access into the `/var/opt/gitlab/wal_restore` directory

```
usermod -a -G gitlab-psql <user>
```

## Using pg_waldump

Documentation https://www.postgresql.org/docs/current/pgwaldump.html

Example

```
/usr/lib/postgresql/14/bin/pg_waldump -p /var/opt/gitlab/wal_restore <startseg>
```
