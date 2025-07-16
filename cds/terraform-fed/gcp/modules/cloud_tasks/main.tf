terraform {
  required_version = ">= 1.9.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.17.0"
    }
  }
}

resource "google_cloud_tasks_queue" "scanjob_queue" {
  project  = var.project_id
  name     = var.scanjob_retry_queue_name
  location = var.queue_location

  retry_config {
    max_attempts = 5
    max_backoff  = "3600s"
    min_backoff  = "10s"
  }
}
