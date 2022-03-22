terraform {
  required_version = ">= 1.1"

  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 1.20.1"
    }
    jsonnet = {
      source  = "peikk0/jsonnet"
      version = "~> 2.0.1"
    }
  }
}
