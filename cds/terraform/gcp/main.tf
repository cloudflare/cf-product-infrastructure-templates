# Provider Configuration
terraform {
  required_version = ">= 1.9.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.17.0"
    }
  }
}

provider "google" {
  project = var.project_id
}

variable "deployment_version" {
  default = "1.0.13"
  type    = string
}

variable "image_tag" {
  default = "v1.0.13-amd64"
  type    = string
}

variable "scanjob_retry_queue_name" {
  default = "cloudflare-cds-scanjobs-retry"
  type    = string
}

variable "vpc_network_name" {
  default = "cloudflare-cds-vpc-network"
  type    = string
}

variable "redis_instance_subnet_name" {
  default = "cloudflare-cds-redis-instance-subnet"
  type    = string
}

variable "enable_debug_logging" {
  description = "Whether to emit debug logs. Enabling this option may incur additional costs."
  type        = bool

  default = false

}


locals {
  control_image                          = "us-docker.pkg.dev/cloudflare-casb-official/cds/control:${var.image_tag}"
  crawler_image                          = "us-docker.pkg.dev/cloudflare-casb-official/cds/crawler:${var.image_tag}"
  scanner_image                          = "us-docker.pkg.dev/cloudflare-casb-official/cds/scanner:${var.image_tag}"
  control_cloud_run_service_name         = "cloudflare-cds-control-cloud-run-service"
  control_cloud_run_scheduler_name       = "cloudflare-cds-control-cloud-run-service-scheduler-trigger"
  crawler_cloud_run_service_name         = "cloudflare-cds-crawler-cloud-run-service"
  scanner_cloud_run_service_name         = "cloudflare-cds-scanner-cloud-run-service"
  discovery_crawler_pubsub_sub           = "cloudflare-cds-discovery-crawler-sub"
  discovery_pubsub_topic_name            = "cloudflare-cds-discovery"
  kms_keyring_name                       = "cloudflare-cds-kms-keyring"
  kms_key_name                           = "cloudflare-cds-kms-key"
  scanjob_pubsub_topic_name              = "cloudflare-cds-scanjobs"
  scanjob_pubsub_sub                     = "cloudflare-cds-scanjob-scanner-sub"
  transmission_pubsub_sub                = "cloudflare-cds-transmission-control-sub"
  transmission_pubsub_topic_name         = "cloudflare-cds-transmissions"
  scanresult_pubsub_sub                  = "cloudflare-cds-scanresult-control-sub"
  scanresult_pubsub_topic_name           = "cloudflare-cds-scanresults"
  scanjob_retry_queue_name               = var.scanjob_retry_queue_name
  secret_name                            = "cloudflare-cds-secret"
  vpc_network_name                       = var.vpc_network_name
  redis_instance_name                    = "cloudflare-cds-redis-instance"
  redis_instance_subnet_name             = var.redis_instance_subnet_name
  redis_vpc_connection_policy_name       = "cloudflare-cds-redis-connection-policy"
  deployment_version                     = var.deployment_version
  cloud_vendor                           = "gcp"
  cloudflare_cds_service_account_id      = "cf-cds-sa"
  cloudflare_owned_service_account_email = "cloudflare-cds-sa@cloudflare-casb-official.iam.gserviceaccount.com"
  redis_private_ip_alloc_name            = "cloudflare-cds-redis-private-ip-alloc"
}

data "google_project" "current" {}

resource "google_project_service" "cloudresourcemanager" {
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
  project            = var.project_id
}

module "apis" {
  source     = "./modules/apis"
  project_id = var.project_id
  depends_on = [google_project_service.cloudresourcemanager]
}

module "vpc" {
  source                              = "./modules/vpc"
  project_id                          = var.project_id
  vpc_network_name                    = local.vpc_network_name
  redis_instance_subnet_name          = local.redis_instance_subnet_name
  redis_vpc_connection_policy_name    = local.redis_vpc_connection_policy_name
  redis_instance_region               = var.region
  redis_instance_subnet_region        = var.region
  redis_instance_subnet_ip_cidr_range = "10.0.0.0/24"
  redis_private_ip_alloc_name         = local.redis_private_ip_alloc_name
  depends_on                          = [module.apis.apis]
}

module "pubsub" {
  source                         = "./modules/pubsub"
  project_id                     = var.project_id
  discovery_pubsub_topic_name    = local.discovery_pubsub_topic_name
  scanjobs_pubsub_topic_name     = local.scanjob_pubsub_topic_name
  transmission_pubsub_sub        = local.transmission_pubsub_sub
  transmission_pubsub_topic_name = local.transmission_pubsub_topic_name
  scanresult_pubsub_topic_name   = local.scanresult_pubsub_topic_name
  scanresult_control_pubsub_sub  = local.scanresult_pubsub_sub
  depends_on                     = [module.apis.apis]
}

module "cloud_tasks" {
  source                     = "./modules/cloud_tasks"
  project_id                 = var.project_id
  project_number             = data.google_project.current.number
  cloud_run_service_location = var.region
  scanjob_retry_queue_name   = local.scanjob_retry_queue_name
  crawler_service_name       = local.crawler_cloud_run_service_name
  queue_location             = var.region
  depends_on                 = [module.apis.apis]
}

module "iam" {
  source                            = "./modules/iam"
  project_id                        = var.project_id
  cloudflare_cds_service_account_id = local.cloudflare_cds_service_account_id
  depends_on                        = [module.apis.apis]
}

module "redis" {
  source                = "./modules/redis"
  project_id            = var.project_id
  redis_instance_name   = local.redis_instance_name
  redis_instance_region = var.region
  vpc_network_id        = module.vpc.vpc_network.id
  depends_on            = [module.apis.apis, module.vpc.redis_service_connection_policy]
}

module "cloud_scheduler" {
  source                                        = "./modules/cloud_scheduler"
  project_id                                    = var.project_id
  control_cloud_run_scheduler_name              = local.control_cloud_run_scheduler_name
  control_cloud_scheduler_service_account_email = module.iam.control_cloud_scheduler_service_account.email
  control_cloud_run_uri                         = module.cloud_run.control_cloud_run_service.uri
  control_scheduler_region                      = var.region
}

module "cloud_run" {
  source                                  = "./modules/cloud_run"
  project_id                              = var.project_id
  crawler_cloud_run_service_name          = local.crawler_cloud_run_service_name
  control_cloud_run_service_name          = local.control_cloud_run_service_name
  scanner_cloud_run_service_name          = local.scanner_cloud_run_service_name
  cloud_run_location                      = var.region
  control_image                           = local.control_image
  crawler_image                           = local.crawler_image
  crawler_cloud_run_service_account_email = module.iam.crawler_cloud_run_service_account.email
  scanner_image                           = local.scanner_image
  scanner_cloud_run_service_account_email = module.iam.scanner_cloud_run_service_account.email
  control_cloud_run_service_account_email = module.iam.control_cloud_run_service_account.email
  discovery_pubsub_topic                  = local.discovery_pubsub_topic_name
  discovery_crawler_pubsub_sub            = local.discovery_crawler_pubsub_sub
  redis_instance_host                     = module.redis.redis_instance.host
  redis_instance_port                     = module.redis.redis_instance.port
  vpc_network_id                          = module.vpc.vpc_network.id
  redis_subnet_id                         = module.vpc.redis_subnet.id
  scanjob_pubsub_topic                    = local.scanjob_pubsub_topic_name
  scanjob_pubsub_sub                      = local.scanjob_pubsub_sub
  scanresult_pubsub_topic                 = local.scanresult_pubsub_topic_name
  scanresult_pubsub_sub                   = local.scanresult_pubsub_sub
  transmission_pubsub_topic               = local.transmission_pubsub_topic_name
  transmission_pubsub_sub                 = local.transmission_pubsub_sub
  kms_key_name                            = local.kms_key_name
  deployment_version                      = local.deployment_version
  scanjob_cloudtask_queue_uri             = local.scanjob_retry_queue_name
  cloud_vendor                            = local.cloud_vendor
  secret_name                             = local.secret_name
  depends_on                              = [module.apis.apis]
  cloud_task_queue_location               = var.region
  project_number                          = data.google_project.current.number
  enable_debug_logging                    = var.enable_debug_logging
}

module "kms_keyring" {
  source           = "./modules/kms_keyring"
  project_id       = var.project_id
  kms_keyring_name = local.kms_keyring_name
  depends_on       = [module.apis.apis]
}

module "kms" {
  source         = "./modules/kms"
  project_id     = var.project_id
  kms_keyring_id = module.kms_keyring.cloudflare_cds_kms_keyring.id
  kms_key_name   = local.kms_key_name
  depends_on     = [module.apis.apis, module.kms_keyring]
}

module "secrets" {
  source          = "./modules/secrets"
  project_id      = var.project_id
  cds_secret_name = local.secret_name
  depends_on      = [module.apis.apis]
}

module "iam_bindings" {
  source     = "./modules/iam-bindings"
  project_id = var.project_id

  cloudflare_cds_service_account_id        = module.iam.cloudflare_cds_service_account.id
  cloudflare_cds_service_account_email     = module.iam.cloudflare_cds_service_account.email
  cloudflare_owned_service_account_email   = local.cloudflare_owned_service_account_email
  control_cloud_run_iam_role               = module.iam.control_cloud_run_iam_role
  control_cloud_run_service                = module.cloud_run.control_cloud_run_service
  control_scheduler_service_account_email  = module.iam.control_cloud_scheduler_service_account.email
  control_service_account_email            = module.iam.control_cloud_run_service_account.email
  crawler_cloud_run_iam_role               = module.iam.crawler_cloud_run_iam_role
  crawler_cloud_run_service                = module.cloud_run.crawler_cloud_run_service
  crawler_service_account_email            = module.iam.crawler_cloud_run_service_account.email
  discovery_crawler_pubsub_subscription_id = module.cloud_run.discovery_crawler_pubsub_subscription.id
  discovery_pubsub_topic                   = module.pubsub.discovery_pubsub_topic.id
  kms_key_id                               = module.kms.cloudflare_cds_kms_key.id
  queue_location                           = var.region
  scanjob_pubsub_topic                     = module.pubsub.scanjob_pubsub_topic.id
  scanjob_retry_queue                      = module.cloud_tasks.scanjob_retry_queue.id
  scanner_cloud_run_iam_role               = module.iam.scanner_cloud_run_iam_role
  scanner_cloud_run_service                = module.cloud_run.scanner_cloud_run_service
  scanner_service_account_email            = module.iam.scanner_cloud_run_service_account.email
  scanresult_pubsub_topic                  = module.pubsub.scanresult_pubsub_topic.id
  scanresult_pubsub_subscription_id        = module.pubsub.scanresult_control_pubsub_sub.id
  transmission_pubsub_topic                = module.pubsub.transmission_pubsub_topic.id
  transmission_pubsub_subscription_id      = module.pubsub.transmission_control_pubsub_sub.id
  cds_secret_manager_secret_id             = module.secrets.cds_secret_manager_secret_id
}
