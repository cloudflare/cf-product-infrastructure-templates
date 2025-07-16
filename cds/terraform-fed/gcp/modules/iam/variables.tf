variable "project_id" {
  description = "The identifier for the project to which the cloudflare cds deployment is deployed"
  type        = string
}

variable "control_cloud_run_service_account_id" {
  description = "The account id that is used to generate the service account email address and a stable unique id. It is unique within a project, must be 6-30 characters long, and match the regular expression [a-z]([-a-z0-9]*[a-z0-9]) to comply with RFC1035"
  type        = string
  default     = "cf-cds-control-sa"
}

variable "control_cloud_scheduler_service_account_id" {
  description = "The account id that is used to generate the service account email address and a stable unique id. It is unique within a project, must be 6-30 characters long, and match the regular expression [a-z]([-a-z0-9]*[a-z0-9]) to comply with RFC1035"
  type        = string
  default     = "cf-cds-control-schd-sa"
}

variable "crawler_cloud_run_service_account_id" {
  description = "The account id that is used to generate the service account email address and a stable unique id. It is unique within a project, must be 6-30 characters long, and match the regular expression [a-z]([-a-z0-9]*[a-z0-9]) to comply with RFC1035"
  type        = string
  default     = "cf-cds-crawler-sa"
}
variable "scanner_cloud_run_service_account_id" {
  description = "The account id that is used to generate the service account email address and a stable unique id. It is unique within a project, must be 6-30 characters long, and match the regular expression [a-z]([-a-z0-9]*[a-z0-9]) to comply with RFC1035"
  type        = string
  default     = "cf-cds-scanner-sa"
}

variable "cloudflare_cds_service_account_id" {
  description = "The account id that is impersonated by cloudflare services"
  type        = string
}