terraform {
  required_version = ">= 1.9.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.17.0"
    }
  }
}

resource "google_secret_manager_secret" "cds_secret_manager_secret" {
  project   = var.project_id
  secret_id = var.cds_secret_name

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "cds_secrets" {
  secret = google_secret_manager_secret.cds_secret_manager_secret.id
  secret_data = jsonencode({
    cloudflare_api_token = var.cloudflare_api_token
  })

  lifecycle {
    ignore_changes = [secret_data]
  }
}