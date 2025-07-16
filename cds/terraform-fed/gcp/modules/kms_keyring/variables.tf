variable "project_id" {
  description = "The identifier for the project to which the cloudflare cds deployment is deployed"
  type        = string
}

variable "kms_keyring_name" {
  description = "The name of the kms key ring housing the kms key used to encrypt sensitive information"
  type        = string
}