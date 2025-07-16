terraform {
  required_version = ">= 1.9.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.17.0"
    }
  }
}

resource "google_redis_instance" "redis_instance" {
  name               = var.redis_instance_name
  memory_size_gb     = 5
  region             = var.redis_instance_region
  authorized_network = var.vpc_network_id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"


  redis_version = "REDIS_7_0"
  persistence_config {
    persistence_mode = "RDB"
    # snapshot every 1 hour
    rdb_snapshot_period = "ONE_HOUR"
  }
}
