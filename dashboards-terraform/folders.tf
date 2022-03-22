locals {
  folder_titles = {
    "alerts"               = "Alerts"
    "api"                  = "API Service"
    "camoproxy"            = "Camoproxy"
    "ci-runners"           = "CI Runners"
    "cloud-sql"            = "Cloud SQL"
    "consul"               = "Consul"
    "delivery"             = "Delivery"
    "diagrams"             = "Diagrams"
    "frontend"             = "Frontend"
    "general"              = "General Metrics"
    "git"                  = "Git Service"
    "gitaly"               = "Gitaly Service"
    "google-cloud-storage" = "Google Cloud Storage"
    "importers"            = "Importers"
    "jaeger"               = "Jaeger"
    "kas"                  = "KAS (Kubernetes Agent Server)"
    "kube"                 = "Kube"
    "kubernetes"           = "Kubernetes"
    "logging"              = "Logging Stack"
    "mailroom"             = "Mailroom"
    "marquee"              = "Marquee"
    "monitoring"           = "Monitoring Stack"
    "nat"                  = "Cloud NAT"
    "nginx"                = "Nginx"
    "patroni"              = "Patroni Service"
    "patroni-ci"           = "Patroni CI"
    "patroni-registry"     = "Patroni Registry"
    "pgbouncer"            = "PgBouncer Service"
    "pgbouncer-ci"         = "PgBouncer CI"
    "pgbouncer-registry"   = "PgBouncer Registry"
    "plantuml"             = "PlantUML"
    "postgres-archive"     = "PostgreSQL Archive"
    "praefect"             = "Praefect"
    "product"              = "Product"
    "product-intelligence" = "Product Intelligence"
    "pvs"                  = "Pipeline Validation Service"
    "redis"                = "Redis Service"
    "redis-cache"          = "Redis Cache"
    "redis-ratelimiting"   = "Redis Rate-limiting"
    "redis-sessions"       = "Redis Sessions"
    "redis-sidekiq"        = "Redis Sidekiq"
    "redis-tracechunks"    = "Redis Tracechunks"
    "registry"             = "Container Registry"
    "search"               = "Search (Elasticsearch)"
    "sentry"               = "Sentry"
    "sidekiq"              = "Sidekiq Service"
    "stage-groups"         = "Stage Groups"
    "waf"                  = "WAF"
    "web"                  = "Web Service"
    "web-pages"            = "Web Pages"
    "websockets"           = "Websockets Service"
    "woodhouse"            = "Woodhouse"
  }

  folders = {
    for uid in toset([for id, dashboard in local.all_dashboards : dashboard.folder]) :
    uid => lookup(local.folder_titles, uid, uid)
  }
}

resource "grafana_folder" "folder" {
  for_each = local.folders

  title = each.value
  uid   = each.key
}
