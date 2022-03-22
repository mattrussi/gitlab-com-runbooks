terraform {
  backend "http" {
    address = "https://ops.gitlab.net/api/v4/projects/122/terraform/state/dashboards"
    // user = $TF_HTTP_USERNAME
    // password = $TF_HTTP_PASSWORD
    lock_address   = "https://ops.gitlab.net/api/v4/projects/122/terraform/state/dashboards/lock"
    unlock_address = "https://ops.gitlab.net/api/v4/projects/122/terraform/state/dashboards/lock"
    lock_method    = "POST"
    unlock_method  = "DELETE"
    retry_wait_min = 5
  }
}
