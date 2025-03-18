output "cds_secret_manager_secret_id" {
  description = "The id of the cds secret manager secret"
  value       = google_secret_manager_secret.cds_secret_manager_secret.id
}