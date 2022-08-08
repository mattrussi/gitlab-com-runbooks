# Cloud SQL Troubleshooting

Some services such as Praefect, `ops.gitlab.net` or Grafana use a Google Cloud
SQL PostgreSQL instance.

On occasion it will be necessary to connect to it interactively in a `psql`
shell. As with all manual database access, this should be kept to a minimum,
and frequently-requested information should be exposed as Prometheus metrics if
possible.

# Praefect Database

See [here](../praefect/praefect-database.md) for troubleshooting the Praefect Cloud SQL database.

# General case

## Logs

The Cloud SQL logs can be accessed in the
[Operations console](https://cloudlogging.app.goo.gl/uJN6NWcjtK8mwaN89).

## Query Insights

The [Query Insights](https://cloud.google.com/sql/docs/postgres/using-query-insights)
dashboard can be used to detect and analyze performance problems. To use it,
either go to the *Query Insights* tab of the Cloud SQL instance in the GCP
console, or
[enable it via Terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance#query_insights_enabled).

# Connecting to the Cloud SQL database

1. Retrieve the user and password for the database from the application configuration (GKMS for Chef, Terraform state, other...)
2. Find the instance you are targetting:

   ```
   gcloud --project gitlab-production sql instances list
   ```

3. Connect to the instance using `gcloud` (paste in the password when prompted):

   ```
   gcloud --project gitlab-production sql connect <instance> -u <user>
   ```
