terraform {
  required_version = ">= 1.1"

  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 1.20.1"
    }
    jsonnet = {
      source  = "alxrem/jsonnet"
      version = "~> 2.1.0"
    }
  }
}
