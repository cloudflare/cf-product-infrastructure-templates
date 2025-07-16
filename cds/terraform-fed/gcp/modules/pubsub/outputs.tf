output "discovery_pubsub_topic" {
  description = "The object discovery pubsub topic"
  value       = google_pubsub_topic.discovery_pubsub_topic
}

output "scanjob_pubsub_topic" {
  description = "The scanjob pubsub topic"
  value       = google_pubsub_topic.scanjob_pubsub_topic
}

output "transmission_pubsub_topic" {
  description = "The transmission pubsub topic"
  value       = google_pubsub_topic.transmission_pubsub_topic
}

output "transmission_control_pubsub_sub" {
  description = "The scanresult control pubsub subscription"
  value       = google_pubsub_subscription.transmission_pubsub_subscription
}

output "scanresult_pubsub_topic" {
  description = "The scanresult pubsub topic"
  value       = google_pubsub_topic.scanresult_pubsub_topic
}

output "scanresult_control_pubsub_sub" {
  description = "The scanresult control pubsub subscription"
  value       = google_pubsub_subscription.scanresult_control_pubsub_subscription
}
