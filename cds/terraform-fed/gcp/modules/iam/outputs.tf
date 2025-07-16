output "control_cloud_run_service_account" {
  description = "The service account created for the control cloud run service"
  value       = google_service_account.control_cloud_run_service_account
}

output "control_cloud_run_iam_role" {
  description = "Custom role for the cloudflare cds control cloud run service"
  value       = google_project_iam_custom_role.control_cloud_run_iam_role
}

output "control_cloud_scheduler_service_account" {
  description = "The service account created for the control cloud scheduler"
  value       = google_service_account.control_cloud_scheduler_service_account
}

output "crawler_cloud_run_service_account" {
  description = "The service account created for the crawler cloud run service"
  value       = google_service_account.crawler_cloud_run_service_account
}

output "crawler_cloud_run_iam_role" {
  description = "Custom role for the cloudflare cds crawler cloud run service"
  value       = google_project_iam_custom_role.crawler_cloud_run_iam_role
}

output "scanner_cloud_run_service_account" {
  description = "The service account created for the crawler cloud run service"
  value       = google_service_account.scanner_cloud_run_service_account
}

output "scanner_cloud_run_iam_role" {
  description = "Custom role for the cloudflare cds scanner cloud run service"
  value       = google_project_iam_custom_role.scanner_cloud_run_iam_role
}

output "cloudflare_cds_service_account" {
  description = "The service account that will be impersonated by a cloudflare-owned service account"
  value       = google_service_account.cloudflare_cds_service_account
}
