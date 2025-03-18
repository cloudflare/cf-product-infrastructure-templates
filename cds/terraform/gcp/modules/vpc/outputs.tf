output "vpc_network" {
  value = google_compute_network.vpc_network
}

output "redis_subnet" {
  value = google_compute_subnetwork.redis_instance_subnet
}

output "redis_service_connection_policy" {
  value = google_service_networking_connection.redis_private_service_connection
}
