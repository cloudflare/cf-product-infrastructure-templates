terraform {
  required_version = ">= 1.9.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.17.0"
    }
  }
}

# Creates a service account for the control cloudrun service
resource "google_service_account" "control_cloud_run_service_account" {
  account_id   = var.control_cloud_run_service_account_id
  display_name = "Cloudflare CDS Control Cloud Run Service Account"
  project      = var.project_id
}

resource "google_project_iam_custom_role" "control_cloud_run_iam_role" {
  role_id     = "CloudflareCDSControlRole"
  title       = "Cloudflare CDS Control Role"
  description = "Custom role for the cloudflare cds cloud-run-service"
  permissions = [
    "pubsub.topics.publish",
    "pubsub.subscriptions.consume",
    "monitoring.timeSeries.list"
  ]
  project = var.project_id
}

# Creates a service account for the control cloud scheduler
resource "google_service_account" "control_cloud_scheduler_service_account" {
  account_id   = var.control_cloud_scheduler_service_account_id
  display_name = "Cloudflare CDS Control Cloud Scheduler Service Account"
  project      = var.project_id
}

# Creates a service account for the crawler cloudrun job
resource "google_service_account" "crawler_cloud_run_service_account" {
  account_id   = var.crawler_cloud_run_service_account_id
  display_name = "Cloudflare CDS Crawler Cloud Run Service Account"
  project      = var.project_id
}

resource "google_project_iam_custom_role" "crawler_cloud_run_iam_role" {
  role_id     = "CloudflareCDSCrawlerRole"
  title       = "Cloudflare CDS Crawler Role"
  description = "Custom role for the cloudflare cds cloud-run-service"
  permissions = [
    "pubsub.topics.publish",
    "pubsub.subscriptions.consume",
    "cloudtasks.tasks.create",
  ]
  project = var.project_id
}

resource "google_project_iam_custom_role" "scanner_cloud_run_iam_role" {
  role_id     = "CloudflareCDSScannerRole"
  title       = "Cloudflare CDS Scanner Role"
  description = "Custom role for the cloudflare cds cloud-run-service"
  permissions = [
    "pubsub.topics.publish",
    "pubsub.subscriptions.consume",
    "cloudtasks.tasks.create",
  ]
  project = var.project_id
}

# Creates a service account for the scanner cloudrun job
resource "google_service_account" "scanner_cloud_run_service_account" {
  account_id   = var.scanner_cloud_run_service_account_id
  display_name = "Cloudflare CDS Scanner Cloud Run Service Account"
  project      = var.project_id
}

# Creates the CDS service account
resource "google_service_account" "cloudflare_cds_service_account" {
  account_id   = var.cloudflare_cds_service_account_id
  display_name = "Cloudflare CDS Service Account"
  project      = var.project_id
}
