terraform {
  required_version = ">= 1.9.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.17.0"
    }
  }
}

resource "google_compute_network" "vpc_network" {
  project                 = var.project_id
  name                    = var.vpc_network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "redis_instance_subnet" {
  name          = var.redis_instance_subnet_name
  project       = var.project_id
  network       = google_compute_network.vpc_network.id
  ip_cidr_range = var.redis_instance_subnet_ip_cidr_range
  region        = var.redis_instance_subnet_region
}

resource "google_compute_global_address" "redis_private_ip_allocation" {
  name          = var.redis_private_ip_alloc_name
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_network.id
}

# Set up private service access connection
resource "google_service_networking_connection" "redis_private_service_connection" {
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.redis_private_ip_allocation.name]
}
