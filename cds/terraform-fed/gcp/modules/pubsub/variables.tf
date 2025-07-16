variable "project_id" {
  description = "The identifier for the project to which the cloudflare cds deployment is deployed"
  type        = string
}

variable "discovery_pubsub_topic_message_retention_duration" {
  description = "Indicates the minimum duration to retain a message after it is published to the object discovery topic"
  type        = string
  default     = "1209600s" # 14 days (in seconds)
}

variable "scanjob_pubsub_topic_message_retention_duration" {
  description = "Indicates the minimum duration to retain a message after it is published to the scanjob topic"
  type        = string
  default     = "1209600s" # 14 days (in seconds)
}

variable "transmission_pubsub_topic_message_retention_duration" {
  description = "Indicates the minimum duration to retain a message after it is published to the transmission topic"
  type        = string
  default     = "1209600s" # 14 days (in seconds)
}

variable "scanresult_pubsub_topic_message_retention_duration" {
  description = "Indicates the minimum duration to retain a message after it is published to the scanresulttopic"
  type        = string
  default     = "1209600s" # 14 days (in seconds)
}

variable "discovery_pubsub_topic_name" {
  description = "The name to use for the object discovery pubsub topic"
  type        = string
}

variable "scanjobs_pubsub_topic_name" {
  description = "The name to use for the scanjobs pubsub topic"
  type        = string
}

variable "transmission_pubsub_topic_name" {
  description = "The name to use for the transmission pubsub topic"
  type        = string
}

variable "transmission_pubsub_sub" {
  description = "The name to use for the transmission pubsub subscription consumed by the control"
  type        = string
}

variable "scanresult_pubsub_topic_name" {
  description = "The name to use for the scanresult pubsub topic"
  type        = string
}

variable "scanresult_control_pubsub_sub" {
  description = "The name to use for the scanresult pubsub subscription consumed by the control"
  type        = string
}
