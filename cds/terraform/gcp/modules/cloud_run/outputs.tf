output "crawler_cloud_run_service" {
  value = google_cloud_run_v2_service.crawler_cloud_run_service
}

output "control_cloud_run_service" {
  value = google_cloud_run_v2_service.control_cloud_run_service
}

output "scanner_cloud_run_service" {
  value = google_cloud_run_v2_service.scanner_cloud_run_service
}

output "discovery_crawler_pubsub_subscription" {
  value = google_pubsub_subscription.discovery_crawler_pubsub_subscription
}

output "scanjob_scanner_pubsub_subscription" {
  value = google_pubsub_subscription.scanjob_scanner_pubsub_subscription
}