variable "project_id" {
  description = "The identifier for the project to which the cloudflare cds deployment is deployed"
  type        = string
}

variable "redis_instance_name" {
  description = "The name to identify the CDS redis instance"
  type        = string
}

variable "redis_instance_region" {
  description = "The GCP region for the redis_instance"
  type        = string
}

variable "vpc_network_id" {
  description = "The identifier for the network in which the cloudflare cds deployment components are deployed"
  type        = string
}
