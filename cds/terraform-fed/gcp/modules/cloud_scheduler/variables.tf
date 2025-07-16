variable "project_id" {
  description = "The identifier for the project to which the cloudflare cds deployment is deployed"
  type        = string
}

variable "control_cloud_run_scheduler_name" {
  description = "The identifier for the specific control cloud run service scheduler job"
  type        = string
}

variable "control_cloud_scheduler_service_account_email" {
  description = "email associated with service account for control cloud scheduler"
  type        = string
}

variable "control_cloud_run_uri" {
  description = "function uri for cloud scheduler to call via http request"
  type        = string
}

variable "control_scheduler_region" {
  description = "The location in which to deploy the control job scheduler from cloud_run_scheduler"
  type        = string
}
