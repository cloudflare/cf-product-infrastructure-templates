variable "project_id" {
  description = "The identifier for the project to which the cloudflare cds deployment is deployed"
  type        = string
}

variable "control_cloud_run_service" {
  description = "The control cloud-run service"
  type = object({
    id         = string
    uid        = string
    generation = number
    name       = string
    location   = string
  })
}

variable "control_cloud_run_iam_role" {
  description = "The iam role for the Cloudflare CDS Control cloud run service"
  type = object({
    id   = string
    name = string
  })
}

variable "control_service_account_email" {
  description = "The email of the service account associated with the control cloud run service"
  type        = string
}

variable "control_scheduler_service_account_email" {
  description = "The email of the service account associated with the control cloud scheduler"
  type        = string
}

variable "transmission_pubsub_subscription_id" {
  description = "Identifier for the pubsub subscription used to pull messages from transmission queue"
  type        = string
}

variable "crawler_cloud_run_iam_role" {
  description = "The iam role for the Cloudflare CDS Crawler cloud run service"
  type = object({
    id   = string
    name = string
  })
}

variable "crawler_cloud_run_service" {
  description = "The crawler cloud-run service"
  type = object({
    id         = string
    uid        = string
    generation = number
    name       = string
    location   = string
  })
}

variable "crawler_service_account_email" {
  description = "The email of the service account associated with the crawler cloud run service"
  type        = string
}

variable "scanner_cloud_run_iam_role" {
  description = "The iam role for the Cloudflare CDS Scanner cloud run service"
  type = object({
    id   = string
    name = string
  })
}

variable "scanner_cloud_run_service" {
  description = "The scanner cloud-run service"
  type = object({
    id         = string
    uid        = string
    generation = number
    name       = string
    location   = string
  })
}

variable "scanner_service_account_email" {
  description = "The email of the service account associated with the scanner cloud run service"
  type        = string
}

variable "discovery_pubsub_topic" {
  description = "The name of the object discovery pubsub topic"
  type        = string
}

variable "discovery_crawler_pubsub_subscription_id" {
  description = "Identifier for the pubsub subscription used to invoke the crawler cloudrun service"
  type        = string
}

variable "scanjob_pubsub_topic" {
  description = "The name of the scanjob pubsub topic"
  type        = string
}

variable "scanresult_pubsub_topic" {
  description = "The name of the object scanresult pubsub topic"
  type        = string
}

variable "transmission_pubsub_topic" {
  description = "The name of the transmission pubsub topic"
  type        = string
}

variable "queue_location" {
  description = "The location to which the cloudtask queue(s) are deployed"
  type        = string
}

variable "scanjob_retry_queue" {
  description = "ID of the scanjob retry queue"
  type        = string
}

variable "cloudflare_cds_service_account_id" {
  description = "The id of the service account that will be impersonated by cloudflare's google service account"
  type        = string
}

variable "cloudflare_cds_service_account_email" {
  description = "The email of the service account that will be impersonated by cloudflare's google service account"
  type        = string
}

variable "cloudflare_owned_service_account_email" {
  description = "The id of the service account owned by cloudflare which will impersonate the service account created by this terraform plan"
  type        = string
}

variable "scanresult_pubsub_subscription_id" {
  description = "The id of the subscription created for the scanresult pubsub topic which will be consumed by cloudflare service accounts"
  type        = string
}

variable "kms_key_id" {
  description = "The identifier of the kms key used by cloudflare cds resources to encrypt and decrypt sensitive materials"
  type        = string
}

variable "cds_secret_manager_secret_id" {
  description = "The id of the secret storing the cloduflare_api_token"
  type        = string
}
