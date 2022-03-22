locals {
  dashboards_dir                  = "${path.root}/../dashboards"
  dashboard_jsonnet_files         = fileset(local.dashboards_dir, "**/*.{json,jsonnet}")
  shared_dashboards_jsonnet_files = fileset(local.dashboards_dir, "**/*.shared.jsonnet")
  test_dashboard_jsonnet_files    = fileset(local.dashboards_dir, "**/*_test.jsonnet")
  single_dashboard_jsonnet_files = setsubtract(
    setsubtract(local.dashboard_jsonnet_files, local.shared_dashboards_jsonnet_files),
    local.test_dashboard_jsonnet_files
  )
}

data "jsonnet_file" "dashboard" {
  for_each = setunion(local.single_dashboard_jsonnet_files, local.shared_dashboards_jsonnet_files)

  source = each.value
}

locals {
  single_dashboards = {
    for dashboard in [
      for path in local.single_dashboard_jsonnet_files :
      {
        name   = split(".", basename(path))[0]
        folder = dirname(path)
        path   = path
        config = jsondecode(data.jsonnet_file.dashboard[path].rendered)
      }
    ] :
    dashboard.path => dashboard if length(dashboard.config) > 0 && contains(keys(dashboard.config), "title")
  }
  shared_dashboards = {
    for dashboard in flatten([
      for path in local.shared_dashboards_jsonnet_files : [
        for name, config in jsondecode(data.jsonnet_file.dashboard[path].rendered) : {
          name   = name
          folder = dirname(path)
          path   = path
          config = config
        }
      ]
    ]) :
    join(":", [dashboard.path, dashboard.name]) => dashboard if length(dashboard.config) > 0 && contains(keys(dashboard.config), "title")
  }
  all_dashboards = {
    for id, dashboard in merge(local.single_dashboards, local.shared_dashboards) :
    join("-", [dashboard.folder, dashboard.name]) => merge(dashboard, {
      config = merge(dashboard.config, {
        uid         = join("-", [dashboard.folder, dashboard.name])
        title       = "${dashboard.folder}: ${dashboard.config.title}"
        description = "Dashboard generated from https://gitlab.com/gitlab-com/runbooks/-/tree/master/dashboards/${dashboard.path}"
        tags        = setunion(lookup(dashboard.config, "tags", []), ["managed", dashboard.folder])
      })
    })
  }
}

resource "grafana_dashboard" "dashboard" {
  for_each = local.all_dashboards

  config_json = jsonencode(each.value.config)
  folder      = grafana_folder.folder[each.value.folder].id
  message     = "Terraformed by ${var.author} at ${timestamp()}"
  overwrite   = true
}
