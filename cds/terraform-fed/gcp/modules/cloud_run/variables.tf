variable "project_id" {
  description = "The identifier for the project to which the cloudflare cds deployment is deployed"
  type        = string
}

variable "project_number" {
  description = "The number of the project to which the cloudflare cds deployment is deployed"
  type        = string
}

variable "cloud_run_location" {
  description = "The location in which to deploy the cds cloud run services"
  type        = string
}

variable "control_image" {
  description = "The image uri to use for the control-cloud-run-service"
  type        = string
}

variable "control_cloud_run_service_name" {
  description = "The name of the control cloud run service"
  type        = string
}

variable "control_cloud_run_service_account_email" {
  description = "Email address of the IAM service account associated with the Task of the control-cloud-run-service. The service account represents the identity of the running task, and determines what permissions the task has"
  type        = string
}

variable "control_cloud_run_limits_cpu" {
  description = "The cpu limit for the control-cloud-run-service"
  type        = string
  default     = "2"
}

variable "control_cloud_run_limits_memory" {
  description = "The memory limit for the control-cloud-run-service. Must be at least 512Mi"
  type        = string
  default     = "512Mi"
}

variable "crawler_image" {
  description = "The image uri to use for the crawler cloudrun service"
  type        = string
}

variable "crawler_cloud_run_service_name" {
  description = "The name of the crawler cloud run service"
  type        = string
}

variable "crawler_cloud_run_service_account_email" {
  description = "Email address of the IAM service account associated with the Task of the crawler-cloud-run-service. The service account represents the identity of the running task, and determines what permissions the task has"
  type        = string
}

variable "scanner_cloud_run_service_account_email" {
  description = "Email address of the IAM service account associated with the Task of the scanner-cloud-run-service. The service account represents the identity of the running task, and determines what permissions the task has"
  type        = string
}

variable "crawler_cloud_run_limits_cpu" {
  description = "The cpu limit for the crawler-cloud-run-service"
  type        = string
  default     = "2"
}

variable "crawler_cloud_run_limits_memory" {
  description = "The memory limit for the crawler-cloud-run-service. Must be at least 512Mi"
  type        = string
  default     = "512Mi"
}

variable "scanner_cloud_run_service_name" {
  description = "The name of the scanner cloud run service"
  type        = string
}

variable "redis_instance_host" {
  description = "The hostname or ip address of the exposed redis endpoint used by clients to connect to the service"
  type        = string
}

variable "redis_instance_port" {
  description = "The port number of the exposed redis endpoint"
  type        = number
}

variable "discovery_pubsub_topic" {
  description = "The PubSub topic that should be subscribed to by the crawler-cloudrun-service"
  type        = string
}

variable "discovery_crawler_pubsub_sub" {
  description = "The PubSub Subscription that should be utilized by the crawler for the discovery topic"
  type        = string
}


variable "vpc_network_id" {
  description = "The id of the vpc network in which cloudflare cds resources reside"
  type        = string
}

variable "redis_subnet_id" {
  description = "The id of the subnet in which the cloudflare-cds-redis cluster resides"
  type        = string
}


variable "scanjob_pubsub_topic" {
  description = "The PubSub topic used for scanjobs"
  type        = string
}

variable "scanjob_pubsub_sub" {
  description = "The PubSub subscription used for scanjobs"
  type        = string
}

variable "scanresult_pubsub_topic" {
  description = "The PubSub topic used for scanresult"
  type        = string
}

variable "scanresult_pubsub_sub" {
  description = "The PubSub subscription used for scanresults"
  type        = string
}

variable "scanjob_cloudtask_queue_uri" {
  description = "The uri of the cloudtask queue used for delayed scanjobs"
  type        = string
}

variable "transmission_pubsub_topic" {
  description = "The PubSub topic used for transmissions"
  type        = string
}

variable "transmission_pubsub_sub" {
  description = "The PubSub subscription used for transmissions"
  type        = string
}

variable "kms_key_name" {
  description = "The name of the kms key used to encrypt sensitive information"
  type        = string
}

variable "secret_name" {
  description = "the name of the secret utilized by cds components"
  type        = string
}

variable "cloud_vendor" {
  description = "The cloud vendor enum value"
  type        = string
}

variable "deployment_version" {
  description = "The version of the deployment"
  type        = string
}

variable "cloud_task_queue_location" {
  description = "The location in which the cloudtask queue(s) are deployed"
  type        = string
}

variable "scanner_image" {
  description = "The image uri to use for the scanner cloud run service"
  type        = string
}

variable "scanner_cloud_run_limits_cpu" {
  description = "The cpu limit for the scanner-cloud-run-service"
  type        = string
  default     = "4"
}

variable "scanner_cloud_run_limits_memory" {
  description = "The memory limit for the scanner-cloud-run-service. Must be at least 512Mi"
  type        = string
  default     = "10Gi"
}

variable "enable_debug_logging" {
  description = "Whether to emit debug logs. Enabling this option may incur additional costs."
  type        = bool
}
