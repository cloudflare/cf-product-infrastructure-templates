variable "project_id" {
  description = "The identifier for the project to which the cloudflare cds deployment is deployed"
  type        = string
}

variable "kms_keyring_id" {
  description = "The identifier for the kms keyring"
  type        = string
}

variable "kms_key_name" {
  description = "The name of the kms key used to encrypt sensitive information"
  type        = string
}
