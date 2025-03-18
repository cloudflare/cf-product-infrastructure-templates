terraform {
  required_version = ">= 1.9.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.17.0"
    }
  }
}

resource "google_pubsub_topic" "discovery_pubsub_topic" {
  name                       = var.discovery_pubsub_topic_name
  message_retention_duration = var.discovery_pubsub_topic_message_retention_duration
  project                    = var.project_id
}

resource "google_pubsub_topic" "scanjob_pubsub_topic" {
  name                       = var.scanjobs_pubsub_topic_name
  message_retention_duration = var.scanjob_pubsub_topic_message_retention_duration
  project                    = var.project_id
}

resource "google_pubsub_topic" "transmission_pubsub_topic" {
  name                       = var.transmission_pubsub_topic_name
  message_retention_duration = var.transmission_pubsub_topic_message_retention_duration
  project                    = var.project_id
}

resource "google_pubsub_subscription" "transmission_pubsub_subscription" {
  name    = var.transmission_pubsub_sub
  topic   = google_pubsub_topic.transmission_pubsub_topic.id
  project = var.project_id

  ack_deadline_seconds = 600
}

resource "google_pubsub_topic" "scanresult_pubsub_topic" {
  name                       = var.scanresult_pubsub_topic_name
  message_retention_duration = var.scanresult_pubsub_topic_message_retention_duration
  project                    = var.project_id
}

resource "google_pubsub_subscription" "scanresult_control_pubsub_subscription" {
  name    = var.scanresult_control_pubsub_sub
  topic   = google_pubsub_topic.scanresult_pubsub_topic.id
  project = var.project_id

  ack_deadline_seconds = 600
}
