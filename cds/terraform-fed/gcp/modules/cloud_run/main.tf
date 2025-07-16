terraform {
  required_version = ">= 1.9.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.17.0"
    }
  }
}

locals {
  control_environment = {
    CDS_CLOUD_VENDOR              = var.cloud_vendor
    CDS_REDIS_HOST                = var.redis_instance_host
    CDS_REDIS_PORT                = var.redis_instance_port
    CDS_GCP_PROJECT_ID            = var.project_id
    CDS_CLOUDRUN_CONTROL_SA_EMAIL = var.control_cloud_run_service_account_email
    CDS_DISCOVERY_TOPIC           = var.discovery_pubsub_topic
    CDS_DISCOVERY_SUBSCRIPTION    = var.discovery_crawler_pubsub_sub
    CDS_TRANSMISSION_TOPIC        = var.transmission_pubsub_topic
    CDS_TRANSMISSION_SUBSCRIPTION = var.transmission_pubsub_sub
    CDS_SCANRESULT_TOPIC          = var.scanresult_pubsub_topic
    CDS_SCANRESULT_SUBSCRIPTION   = var.scanresult_pubsub_sub
    CDS_KMS_KEY_NAME              = var.kms_key_name
    CDS_DEPLOYMENT_VERSION        = var.deployment_version
    CDS_CONTROL_LISTEN_PORT       = "8080"
    CDS_DEBUG_LOGGING             = var.enable_debug_logging
    CDS_SECRET_NAME               = var.secret_name
    CDS_ENVIRONMENT_OVERRIDE      = "prod-fed"
  }

  crawler_environment = {
    CDS_CLOUD_VENDOR                 = var.cloud_vendor
    CDS_REDIS_HOST                   = var.redis_instance_host
    CDS_REDIS_PORT                   = var.redis_instance_port
    CDS_GCP_PROJECT_ID               = var.project_id
    CDS_DISCOVERY_TOPIC              = var.discovery_pubsub_topic
    CDS_DISCOVERY_SUBSCRIPTION       = var.discovery_crawler_pubsub_sub
    CDS_CLOUDRUN_CRAWLER_SA_EMAIL    = var.crawler_cloud_run_service_account_email
    CDS_SCANJOB_TOPIC                = var.scanjob_pubsub_topic
    CDS_SCANJOB_SUBSCRIPTION         = var.scanjob_pubsub_sub
    CDS_SCANJOB_QUEUE_URI            = var.scanjob_cloudtask_queue_uri
    CDS_TRANSMISSION_TOPIC           = var.transmission_pubsub_topic
    CDS_TRANSMISSION_SUBSCRIPTION    = var.transmission_pubsub_sub
    CDS_SCANRESULT_TOPIC             = var.scanresult_pubsub_topic
    CDS_SCANRESULT_SUBSCRIPTION      = var.scanresult_pubsub_sub
    CDS_KMS_KEY_NAME                 = var.kms_key_name
    CDS_DEPLOYMENT_VERSION           = var.deployment_version
    CDS_CRAWLER_LISTEN_PORT          = "8080"
    CDS_DEBUG_LOGGING                = var.enable_debug_logging
    CDS_SECRET_NAME                  = var.secret_name
    CDS_CLOUDTASK_QUEUE_LOCATION     = var.cloud_task_queue_location
    CDS_CRAWLER_CLOUDRUN_SERVICE_URL = "https://${var.crawler_cloud_run_service_name}-${var.project_number}.${var.cloud_run_location}.run.app"
    CDS_SCANNER_CLOUDRUN_SERVICE_URL = "https://${var.scanner_cloud_run_service_name}-${var.project_number}.${var.cloud_run_location}.run.app"
  }


  scanner_environment = {
    # Project & Deployment Settings
    CDS_CLOUD_VENDOR       = var.cloud_vendor
    CDS_GCP_PROJECT_ID     = var.project_id
    CDS_DEPLOYMENT_VERSION = var.deployment_version
    CDS_SECRET_NAME        = var.secret_name

    # Redis Settings
    CDS_REDIS_HOST = var.redis_instance_host
    CDS_REDIS_PORT = var.redis_instance_port

    # Pub/Sub & Queue Settings
    CDS_DISCOVERY_TOPIC           = var.discovery_pubsub_topic
    CDS_DISCOVERY_SUBSCRIPTION    = var.discovery_crawler_pubsub_sub
    CDS_SCANJOB_TOPIC             = var.scanjob_pubsub_topic
    CDS_SCANJOB_SUBSCRIPTION      = var.scanjob_pubsub_sub
    CDS_SCANJOB_QUEUE_NAME        = var.scanjob_cloudtask_queue_uri
    CDS_TRANSMISSION_TOPIC        = var.transmission_pubsub_topic
    CDS_TRANSMISSION_SUBSCRIPTION = var.transmission_pubsub_sub
    CDS_SCANRESULT_TOPIC          = var.scanresult_pubsub_topic
    CDS_SCANRESULT_SUBSCRIPTION   = var.scanresult_pubsub_sub
    CDS_CLOUDTASK_QUEUE_LOCATION  = var.cloud_task_queue_location
    CDS_CLOUDRUN_SCANNER_SA_EMAIL = var.scanner_cloud_run_service_account_email

    # Cloud Run Settings
    CDS_SCANNER_CLOUDRUN_SERVICE_URL = "https://${var.scanner_cloud_run_service_name}-${var.project_number}.${var.cloud_run_location}.run.app"
    CDS_SCANNER_LISTEN_PORT          = 8080

    # KMS Settings
    CDS_KMS_KEY_NAME = var.kms_key_name

    # Debug & Profiling Settings
    CDS_DEBUG_LOGGING                = var.enable_debug_logging
    CDS_SCANNER_PROFILING_ENABLED    = "false"
    CDS_CRAWLER_PROFILING_ENABLED    = "false"
    CDS_PROFILING_BUCKET_DESTINATION = "cde-profiling-bucket"

    # DLP Settings
    CDS_DLP_SCANNER_HOST               = "127.0.0.1"
    CDS_DLP_SCANNER_PORT               = "8000"
    CDS_DLP_SCANNER_METRICS_PORT       = "8001"
    CDS_DLP_SCANNER_METRICS_SCRAPE_SEC = "180"
    CDS_DLP_SCANNER_MAX_CONNECTIONS    = "100"

    # TODO: These variables are currently required but should be removed after we standardize
    CDS_ELASTICACHE_HOST = var.redis_instance_host
    CDS_ELASTICACHE_PORT = var.redis_instance_port
  }
}

resource "google_cloud_run_v2_service" "control_cloud_run_service" {
  name                = var.control_cloud_run_service_name
  location            = var.cloud_run_location
  deletion_protection = false
  project             = var.project_id

  template {
    service_account = var.control_cloud_run_service_account_email
    containers {
      image = var.control_image
      resources {
        limits = {
          cpu    = var.control_cloud_run_limits_cpu
          memory = var.control_cloud_run_limits_memory
        }
      }

      env {
        name  = "GCP_LOCATION"
        value = var.cloud_run_location
      }

      dynamic "env" {
        for_each = local.control_environment
        content {
          name  = env.key
          value = env.value
        }
      }
    }

    vpc_access {
      network_interfaces {
        network    = var.vpc_network_id
        subnetwork = var.redis_subnet_id
      }
    }
  }
}

resource "google_cloud_run_v2_service" "crawler_cloud_run_service" {
  name                = var.crawler_cloud_run_service_name
  location            = var.cloud_run_location
  deletion_protection = false
  project             = var.project_id

  template {
    service_account = var.crawler_cloud_run_service_account_email
    containers {
      image = var.crawler_image
      resources {
        limits = {
          cpu    = var.crawler_cloud_run_limits_cpu
          memory = var.crawler_cloud_run_limits_memory
        }
      }
      env {
        name  = "GCP_LOCATION"
        value = var.cloud_run_location
      }

      dynamic "env" {
        for_each = local.crawler_environment
        content {
          name  = env.key
          value = env.value
        }
      }
    }

    vpc_access {
      network_interfaces {
        network    = var.vpc_network_id
        subnetwork = var.redis_subnet_id
      }
    }
  }
}

resource "google_pubsub_subscription" "discovery_crawler_pubsub_subscription" {
  name    = var.discovery_crawler_pubsub_sub
  topic   = var.discovery_pubsub_topic
  project = var.project_id

  push_config {
    push_endpoint = google_cloud_run_v2_service.crawler_cloud_run_service.uri

    oidc_token {
      service_account_email = var.crawler_cloud_run_service_account_email
    }
  }

  # Optional: Configure retry policy
  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s" # 10 minutes
  }
}

resource "google_cloud_run_v2_service" "scanner_cloud_run_service" {
  name                = var.scanner_cloud_run_service_name
  location            = var.cloud_run_location
  deletion_protection = false
  project             = var.project_id

  template {
    service_account = var.scanner_cloud_run_service_account_email
    containers {
      image = var.scanner_image
      resources {
        limits = {
          cpu    = var.scanner_cloud_run_limits_cpu
          memory = var.scanner_cloud_run_limits_memory
        }
      }

      env {
        name  = "GCP_LOCATION"
        value = var.cloud_run_location
      }

      dynamic "env" {
        for_each = local.scanner_environment
        content {
          name  = env.key
          value = env.value
        }
      }
    }

    vpc_access {
      network_interfaces {
        network    = var.vpc_network_id
        subnetwork = var.redis_subnet_id
      }
    }
  }
}


resource "google_pubsub_subscription" "scanjob_scanner_pubsub_subscription" {
  name    = var.scanjob_pubsub_sub
  topic   = var.scanjob_pubsub_topic
  project = var.project_id

  push_config {
    push_endpoint = google_cloud_run_v2_service.scanner_cloud_run_service.uri

    oidc_token {
      service_account_email = var.scanner_cloud_run_service_account_email
    }
  }

  # Optional: Configure retry policy
  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s" # 10 minutes
  }
}
