provider "grafana" {
  url  = var.grafana_url
  auth = var.grafana_api_key
}

provider "jsonnet" {
  jsonnet_path = join(":", [
    local.dashboards_dir,
    "${path.root}/../libsonnet",
    "${path.root}/../metrics-catalog",
    "${path.root}/../services",
    "${path.root}/../vendor",
  ])
}
