# Praefect Database

The praefect database is a GCP CloudSQL PostgreSQL instance. On occasion it will
be necessary to connect to it interactively in a `psql` shell. As with all
manual database access, this should be kept to a minimum, and
frequently-requested information should be exposed as Prometheus metrics if
possible.

## Connect to the Praefect database

```shell
ssh -t console-01-sv-gprd.c.gitlab-production.internal -- sudo dbconsole-praefect.sh
```
