terraform {
  required_version = ">= 1.9.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.17.0"
    }
  }
}

resource "google_cloud_scheduler_job" "control_scheduler" {
  name             = var.control_cloud_run_scheduler_name
  project          = var.project_id
  region           = var.control_scheduler_region
  description      = "Cloud Scheduler for control service"
  schedule         = "* * * * *"
  time_zone        = "America/New_York"
  attempt_deadline = "320s"

  http_target {
    http_method = "GET"
    uri         = var.control_cloud_run_uri

    oidc_token {
      service_account_email = var.control_cloud_scheduler_service_account_email
    }
  }
}
