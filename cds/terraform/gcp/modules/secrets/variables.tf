variable "project_id" {
  description = "The identifier for the project to which the cloudflare cds deployment is deployed"
  type        = string
}

variable "cds_secret_name" {
  description = "The name of the secret storing the cloduflare_api_token"
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare API Token: the API token your CDS Deployment will use to communicate to the Cloudflare API"
  type        = string
  default     = ""
  sensitive   = true
}