terraform {
  required_version = ">= 1.9.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.17.0"
    }
  }
}

resource "google_pubsub_topic_iam_member" "discovery_control_topic_publisher" {
  project = var.project_id
  topic   = var.discovery_pubsub_topic
  role    = var.control_cloud_run_iam_role.id
  member  = "serviceAccount:${var.control_service_account_email}"
}

resource "google_cloud_run_v2_service_iam_member" "control_cloud_run_service_scheduler_invoker" {
  project  = var.project_id
  location = var.control_cloud_run_service.location
  name     = var.control_cloud_run_service.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.control_scheduler_service_account_email}"
}

resource "google_pubsub_subscription_iam_member" "transmission_control_subscription_consumer" {
  project      = var.project_id
  subscription = var.transmission_pubsub_subscription_id
  role         = var.control_cloud_run_iam_role.id
  member       = "serviceAccount:${var.control_service_account_email}"
}

resource "google_secret_manager_secret_iam_member" "control_secret_access" {
  project   = var.project_id
  secret_id = var.cds_secret_manager_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.control_service_account_email}"
}

resource "google_pubsub_topic_iam_member" "discovery_crawler_topic_publisher" {
  project = var.project_id
  topic   = var.discovery_pubsub_topic
  role    = var.crawler_cloud_run_iam_role.id
  member  = "serviceAccount:${var.crawler_service_account_email}"
}

resource "google_pubsub_topic_iam_member" "scanjob_crawler_topic_publisher" {
  project = var.project_id
  topic   = var.scanjob_pubsub_topic
  role    = var.crawler_cloud_run_iam_role.id
  member  = "serviceAccount:${var.crawler_service_account_email}"
}

resource "google_pubsub_topic_iam_member" "transmission_crawler_topic_publisher" {
  project = var.project_id
  topic   = var.transmission_pubsub_topic
  role    = var.crawler_cloud_run_iam_role.id
  member  = "serviceAccount:${var.crawler_service_account_email}"
}

resource "google_pubsub_subscription_iam_member" "discovery_crawler_subscription_consumer" {
  project      = var.project_id
  subscription = var.discovery_crawler_pubsub_subscription_id
  role         = var.crawler_cloud_run_iam_role.id
  member       = "serviceAccount:${var.crawler_service_account_email}"
}

resource "google_cloud_run_v2_service_iam_member" "crawler_cloud_run_service_pubsub_invoker" {
  project  = var.project_id
  location = var.crawler_cloud_run_service.location
  name     = var.crawler_cloud_run_service.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.crawler_service_account_email}"
}

resource "google_pubsub_topic_iam_member" "transmission_scanner_topic_publisher" {
  project = var.project_id
  topic   = var.transmission_pubsub_topic
  role    = var.scanner_cloud_run_iam_role.id
  member  = "serviceAccount:${var.scanner_service_account_email}"
}

resource "google_pubsub_topic_iam_member" "scanresult_scanner_topic_publisher" {
  project = var.project_id
  topic   = var.scanresult_pubsub_topic
  role    = var.scanner_cloud_run_iam_role.id
  member  = "serviceAccount:${var.scanner_service_account_email}"
}

resource "google_cloud_run_v2_service_iam_member" "scanner_cloud_run_service_invoker" {
  project  = var.project_id
  location = var.scanner_cloud_run_service.location
  name     = var.scanner_cloud_run_service.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.scanner_service_account_email}"
}

resource "google_cloud_tasks_queue_iam_binding" "scanner_iam_binding_scanjob_queue" {
  project  = var.project_id
  location = var.queue_location
  name     = var.scanjob_retry_queue
  role     = "roles/cloudtasks.enqueuer"
  members = [
    "serviceAccount:${var.scanner_service_account_email}"
  ]
}

# Service Account Level Binding
resource "google_service_account_iam_binding" "cloudflare_cds_impersonation" {
  service_account_id = var.cloudflare_cds_service_account_id
  role               = "roles/iam.serviceAccountTokenCreator"
  members = [
    "serviceAccount:${var.cloudflare_owned_service_account_email}"
  ]
}

# Project level IAM binding
resource "google_project_iam_member" "token_creator_project" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${var.cloudflare_owned_service_account_email}"
}

resource "google_project_iam_member" "control_timeseries_query_project" {
  project = var.project_id
  role    = var.control_cloud_run_iam_role.id
  member  = "serviceAccount:${var.control_service_account_email}"
}

resource "google_project_iam_member" "scanner_role_iam_member" {
  project = var.project_id
  role    = var.scanner_cloud_run_iam_role.id
  member  = "serviceAccount:${var.scanner_service_account_email}"
}

resource "google_service_account_iam_member" "scanner_service_account_user" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.scanner_service_account_email}"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.scanner_service_account_email}"
}

resource "google_pubsub_subscription_iam_member" "cloudflare_cds_pubsub_subscriber" {
  subscription = var.scanresult_pubsub_subscription_id
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${var.cloudflare_cds_service_account_email}"
}

resource "google_kms_crypto_key_iam_member" "cloudflare_cds_kms_encrypt" {
  crypto_key_id = var.kms_key_id
  role          = "roles/cloudkms.cryptoKeyEncrypter"
  member        = "serviceAccount:${var.cloudflare_cds_service_account_email}"
}

resource "google_kms_crypto_key_iam_member" "crawler_cds_kms_decrypt" {
  crypto_key_id = var.kms_key_id
  role          = "roles/cloudkms.cryptoKeyDecrypter"
  member        = "serviceAccount:${var.crawler_service_account_email}"
}

resource "google_kms_crypto_key_iam_member" "scanner_kms_decrypt" {
  crypto_key_id = var.kms_key_id
  role          = "roles/cloudkms.cryptoKeyDecrypter"
  member        = "serviceAccount:${var.scanner_service_account_email}"
}

resource "google_kms_crypto_key_iam_member" "control_kms_decrypt" {
  crypto_key_id = var.kms_key_id
  role          = "roles/cloudkms.cryptoKeyDecrypter"
  member        = "serviceAccount:${var.control_service_account_email}"
}
