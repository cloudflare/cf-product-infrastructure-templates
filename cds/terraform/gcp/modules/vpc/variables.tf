variable "project_id" {
  description = "The identifier for the project to which the cloudflare cds deployment is deployed"
  type        = string
}

variable "vpc_network_name" {
  description = "The name for the vpc network"
  type        = string
}

variable "redis_instance_subnet_name" {
  description = "The name for the redis instance subnet"
  type        = string
}

variable "redis_vpc_connection_policy_name" {
  description = "The name for the connection policy between redis_instance_subnet_name and vpc_network_name"
  type        = string
}

variable "redis_instance_region" {
  description = "The GCP region for the redis_instance"
  type        = string
}

variable "redis_instance_subnet_region" {
  description = "The GCP region for the redis_instance subnet"
  type        = string
}

variable "redis_instance_subnet_ip_cidr_range" {
  description = "The range of internal addresses that are owned by the redis_instance_subnet"
  type        = string
}

variable "redis_private_ip_alloc_name" {
  description = "The name to give to the private ip allocation for the redis subnet"
  type        = string
  default     = "cloudflare-cds-redis-private-ip-alloc"
}
