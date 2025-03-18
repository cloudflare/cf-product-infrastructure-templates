variable "project_id" {
  description = "The identifier for the project to which the cloudflare cds deployment is deployed"
  type        = string
}

variable "project_number" {
  description = "The number of the project to which the cloudflare cds deployment is deployed"
  type        = string
}

variable "queue_location" {
  description = "The location to which all queues should be deployed"
  type        = string
}

variable "scanjob_retry_queue_name" {
  description = "The name of the scanjob cloudtasks queue"
  type        = string
}

variable "cloud_run_service_location" {
  description = "The location to which cloudrun services will be deployed"
  type        = string
}

variable "crawler_service_name" {
  description = "The name of the crawler cloud run service"
  type        = string
}
