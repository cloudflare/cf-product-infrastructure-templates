terraform {
  required_version = ">= 1.9.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.80.0"
    }
  }

}

provider "aws" {
  default_tags {
    tags = {
      Application = "cloudflare-cds"

    }
  }
}


variable "cloudflare_api_token" {
  description = "Cloudflare API Token: the API token your CDS Deployment will use to communicate to the Cloudflare API"
  type        = string
  default     = ""
  sensitive   = true
}

variable "enable_debug_logging" {
  description = "Whether to emit debug logs. Enabling this option may incur additional CloudWatch costs."
  type        = bool

  default = false

}

locals {
  cloudflare_cds_service_account_arn = "arn:aws:iam::590183649595:group/cloudflare-cds-service-account"
  cloudflare_cds_kms_key_alias       = "alias/cloudflare-cds-kms-key"
  cds_scanner_ecr                    = "590183649595.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/cde/scanner:v1.0.2-arm64"
  cds_crawler_ecr                    = "590183649595.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/cde/crawler:v1.0.2-arm64"
  cds_control_ecr                    = "590183649595.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/cde/control:v1.0.2-arm64"
  control_schedule_minutes           = 1




  region_availability_zone_id_mapping = {
    "us-east-1" = ["use1-az1", "use1-az2"],
    "us-east-2" = ["use2-az1", "use2-az2"],
    "us-west-1" = ["usw1-az1", "usw1-az2", "usw1-az3"],
    "us-west-2" = ["usw2-az1", "usw2-az2"],
    "eu-west-1" = ["euw1-az1", "euw2-az2"],
  }

  region_elasticache_node_type_mapping = {
    "us-west-1" = "cache.r6g.large",
  }

  default_elasticache_node_type = "cache.r7g.large"

  supported_region_names = sort(keys(local.region_availability_zone_id_mapping))
  num_supported_regions  = length(local.supported_region_names)

  supported_region_names_english = join(" ", [
    "${join(", ", slice(local.supported_region_names, 0, local.num_supported_regions - 1))},",
    "and ${local.supported_region_names[local.num_supported_regions - 1]}",
  ])

  vpc_ipv4_cidr         = "10.10.0.0/16"
  vpc_ipv4_public_cidr  = cidrsubnet(local.vpc_ipv4_cidr, 1, 0)
  vpc_ipv4_private_cidr = cidrsubnet(local.vpc_ipv4_cidr, 1, 1)

  elasticache = {
    port = 6379
  }

  sqs = {
    discovery_visibility_timeout_seconds     = 900
    scanjobs_visibility_timeout_seconds      = 900
    scanresults_visibility_timeout_seconds   = 90
    transmissions_visibility_timeout_seconds = 90
  }

  iam_roles = {
    cloudflare_cds_account_id = "590183649595"
  }

  lambda = {
    control_function_name = "cloudflare-cds-control"
    scanner_concurrency   = 10
    crawler_concurrency   = 10
    control_concurrency   = 1
    lambda_env = {
      CDS_CLOUD_VENDOR         = "aws"
      CDS_DEPLOYMENT_VERSION   = "1.0.0"
      CDS_SCANJOB_SQS_URI      = aws_sqs_queue.scanjobs_queue.url
      CDS_SCANRESULT_SQS_URI   = aws_sqs_queue.scanresults_queue.url
      CDS_DISCOVERY_SQS_URI    = aws_sqs_queue.discovery_queue.url
      CDS_TRANSMISSION_SQS_URI = aws_sqs_queue.transmissions_queue.url
      CDS_ELASTICACHE_PORT     = aws_elasticache_replication_group.elasticache_replication_group.port
      CDS_ELASTICACHE_HOST     = aws_elasticache_replication_group.elasticache_replication_group.configuration_endpoint_address
      CDS_KMS_KEY_ALIAS        = local.cloudflare_cds_kms_key_alias
      CDS_AWS_ACCOUNT_ID       = data.aws_caller_identity.current.account_id
      CDS_SECRETS_ARN          = aws_secretsmanager_secret_version.cds_secrets.arn
      CDS_DEBUG_LOGGING        = tostring(var.enable_debug_logging)

    }
    scanner_only_env = {
      CDS_DLP_SCANNER_HOST               = "127.0.0.1"
      CDS_DLP_SCANNER_PORT               = "8000"
      CDS_DLP_SCANNER_METRICS_PORT       = "8001"
      CDS_DLP_SCANNER_METRICS_SCRAPE_SEC = "180"
    }
  }
}

data "aws_availability_zones" "current" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {
  lifecycle {
    postcondition {
      condition = contains(local.supported_region_names, self.name)
      error_message = join(" ", [
        "The region ${self.name} is not currently supported.",
        "The supported regions are ${local.supported_region_names_english}.",
      ])
    }
  }
}

locals {
  lambda_supported_availability_zone_ids = tolist(setintersection(
    toset(local.region_availability_zone_id_mapping[data.aws_region.current.name]),
    toset(data.aws_availability_zones.current.zone_ids),
  ))

  all_availability_zone_ids = {
    for index, az_id in sort(data.aws_availability_zones.current.zone_ids) :
    az_id => index
  }

  elasticache_node_type = lookup(
    local.region_elasticache_node_type_mapping,
    data.aws_region.current.name,
    local.default_elasticache_node_type,
  )
}

##
# VPC
##
resource "aws_vpc" "vpc" {
  cidr_block                       = local.vpc_ipv4_cidr
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true
  tags = {
    Name = "cloudflare-cds-vpc"
  }
}

locals {
  vpc_ipv6_public_cidr  = cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, 1, 0)
  vpc_ipv6_private_cidr = cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, 1, 1)
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "cloudflare-cds-internet-gateway"
  }
}

resource "aws_subnet" "public_subnet" {
  for_each                        = local.all_availability_zone_ids
  vpc_id                          = aws_vpc.vpc.id
  availability_zone_id            = each.key
  cidr_block                      = cidrsubnet(local.vpc_ipv4_public_cidr, 4, each.value)
  ipv6_cidr_block                 = cidrsubnet(local.vpc_ipv6_public_cidr, 7, each.value)
  assign_ipv6_address_on_creation = true
  map_public_ip_on_launch         = true
  tags = {
    Name = "cloudflare-cds-public-subnet-${each.key}"
  }
}

resource "aws_subnet" "private_subnet" {
  for_each                        = local.all_availability_zone_ids
  vpc_id                          = aws_vpc.vpc.id
  availability_zone_id            = each.key
  cidr_block                      = cidrsubnet(local.vpc_ipv4_private_cidr, 4, each.value)
  ipv6_cidr_block                 = cidrsubnet(local.vpc_ipv6_private_cidr, 7, each.value)
  assign_ipv6_address_on_creation = true
  map_public_ip_on_launch         = false
  tags = {
    Name = "cloudflare-cds-private-subnet-${each.key}"
  }
}

locals {
  public_subnet_ids  = [for subnet in aws_subnet.public_subnet : subnet.id]
  private_subnet_ids = [for subnet in aws_subnet.private_subnet : subnet.id]
  lambda_subnet_ids  = [for az_id in local.lambda_supported_availability_zone_ids : aws_subnet.private_subnet[az_id].id]
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "cloudflare-cds-public-route-table"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_egress_only_internet_gateway.egress_only_internet_gateway.id
  }

  tags = {
    Name = "cloudflare-cds-private-route-table"
  }
}

resource "aws_route_table_association" "public_route_table_association" {
  for_each       = local.all_availability_zone_ids
  subnet_id      = aws_subnet.public_subnet[each.key].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "prviate_route_table_association" {
  for_each       = local.all_availability_zone_ids
  subnet_id      = aws_subnet.private_subnet[each.key].id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_egress_only_internet_gateway" "egress_only_internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "cloudflare-cds-egress-only-internet-gateway"
  }
}

resource "aws_security_group" "lambda_security_group" {
  name        = "cloudflare-cds-lambda-security-group"
  description = "Security group for Cloudflare CDS Lambdas"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "cloudflare-cds-lambda-security-group"
  }
}

resource "aws_vpc_security_group_egress_rule" "lambda_security_group_egress_rule_tcp_443_v4" {
  security_group_id = aws_security_group.lambda_security_group.id
  description       = "Allows IPv4 HTTPS traffic to egress the Cloudflare CDS VPC."

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "lambda_security_group_egress_rule_tcp_443_v6" {
  security_group_id = aws_security_group.lambda_security_group.id
  description       = "Allows IPv6 HTTPS traffic to egress the Cloudflare CDS VPC."

  cidr_ipv6   = "::/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "lambda_security_group_egress_rule_dns_53_v4" {
  security_group_id = aws_security_group.lambda_security_group.id
  description       = "Allows IPv4 DNS traffic to egress the Cloudflare CDS VPC."

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 53
  to_port     = 53
  ip_protocol = "udp"
}

resource "aws_vpc_security_group_egress_rule" "lambda_security_group_egress_rule_dns_53_v6" {
  security_group_id = aws_security_group.lambda_security_group.id
  description       = "Allows IPv6 DNS traffic to egress the Cloudflare CDS VPC."

  cidr_ipv6   = "::/0"
  from_port   = 53
  to_port     = 53
  ip_protocol = "udp"
}

resource "aws_vpc_security_group_egress_rule" "lambda_security_group_egress_rule_elasticache_v4" {
  security_group_id = aws_security_group.lambda_security_group.id
  description       = "Allows Elasticache traffic to egress the Cloudflare CDS lambdas."

  referenced_security_group_id = aws_security_group.elasticache_security_group.id
  from_port                    = local.elasticache.port
  to_port                      = local.elasticache.port
  ip_protocol                  = "tcp"
}

resource "aws_security_group" "vpc_endpoint_security_group" {
  name        = "cloudflare-cds-vpc-security-group"
  description = "Security group for Cloudflare CDS VPC"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "cloudflare-cds-vpc-security-group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoint_security_group_ingress_rule_tcp_443" {
  security_group_id = aws_security_group.vpc_endpoint_security_group.id
  description       = "Allows HTTPS traffic from VPC Private Subnet to ingress the Security Group for VPC Endpoints"

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  referenced_security_group_id = aws_security_group.lambda_security_group.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.public_route_table.id,
    aws_route_table.private_route_table.id
  ]

  tags = {
    Name = "cloudflare-cds-${data.aws_region.current.name}-s3-endpoint"
  }
}

resource "aws_vpc_endpoint" "sqs" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.sqs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = local.private_subnet_ids
  security_group_ids = [
    aws_security_group.vpc_endpoint_security_group.id
  ]
  tags = {
    Name = "cloudflare-cds-${data.aws_region.current.name}-sqs-endpoint"
  }
}

resource "aws_vpc_endpoint" "kms" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.kms"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = local.private_subnet_ids
  security_group_ids = [
    aws_security_group.vpc_endpoint_security_group.id
  ]
  tags = {
    Name = "cloudflare-cds-${data.aws_region.current.name}-kms-endpoint"
  }
}

##
# Elasticache
##
resource "aws_cloudwatch_log_group" "elasticache_log_group" {
  name              = "cloudflare-cds-elasticache-logs"
  retention_in_days = 1
  tags = {
    Name = "cloudflare-cds-elasticache-log-group"
  }
}

resource "aws_security_group" "elasticache_security_group" {
  name        = "cloudflare-cds-elasticache-security-group"
  description = "Security Group providing access to the Cloudflare CDS Elasticache Instance"
  vpc_id      = aws_vpc.vpc.id
  tags = {
    Name = "cloudflare-cds-elasticache-security-group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "elasticache_security_group_ingress_tcp_6379" {
  security_group_id = aws_security_group.elasticache_security_group.id

  from_port                    = local.elasticache.port
  to_port                      = local.elasticache.port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.lambda_security_group.id

  description = "Enables communication from Cloudflare CDS software components to the Elasticache cluster."

  tags = {
    Name = "cloudflare-cds-elasticache-security-group-ingress-rule"
  }
}

resource "aws_elasticache_subnet_group" "elasticache_subnet" {
  name       = "cloudflare-cds-elasticache-subnet"
  subnet_ids = local.private_subnet_ids

  tags = {
    Name = "cloudflare-cds-elasticache-subnet"
  }
}

resource "aws_elasticache_replication_group" "elasticache_replication_group" {
  automatic_failover_enabled = true
  replication_group_id       = "cloudflare-cds"
  description                = "Holds state for the Cloudflare CDS product"
  node_type                  = local.elasticache_node_type
  num_node_groups            = 1
  replicas_per_node_group    = 0
  parameter_group_name       = "default.valkey8.cluster.on"
  engine                     = "valkey"
  engine_version             = "8.0"
  port                       = local.elasticache.port
  subnet_group_name          = aws_elasticache_subnet_group.elasticache_subnet.name
  security_group_ids         = [aws_security_group.elasticache_security_group.id]
  snapshot_retention_limit   = 3
  snapshot_window            = "17:00-18:00"

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.elasticache_log_group.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  tags = {
    Name = "cloudflare-cds"
  }

  lifecycle {
    ignore_changes = [
      num_node_groups,
    ]
  }
}

resource "aws_appautoscaling_target" "elasticache" {
  min_capacity       = 1
  max_capacity       = 1
  service_namespace  = "elasticache"
  resource_id        = "replication-group/${aws_elasticache_replication_group.elasticache_replication_group.replication_group_id}"
  scalable_dimension = "elasticache:replication-group:NodeGroups"
}

resource "aws_appautoscaling_policy" "elasticache" {
  name               = "cloudflare-cds-elasticache-memory-utilization"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.elasticache.resource_id
  scalable_dimension = aws_appautoscaling_target.elasticache.scalable_dimension
  service_namespace  = aws_appautoscaling_target.elasticache.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ElastiCacheDatabaseCapacityUsageCountedForEvictPercentage"
    }

    target_value      = 75
    scale_in_cooldown = 600
  }
}

##
# SQS
##
resource "aws_sqs_queue" "scanjobs_queue" {
  name                       = "cloudflare-cds-scanjobs"
  delay_seconds              = 0
  visibility_timeout_seconds = local.sqs.scanjobs_visibility_timeout_seconds
}

resource "aws_sqs_queue" "scanresults_queue" {
  name                       = "cloudflare-cds-scanresults"
  delay_seconds              = 0
  visibility_timeout_seconds = local.sqs.scanresults_visibility_timeout_seconds
}

resource "aws_sqs_queue" "discovery_queue" {
  name                       = "cloudflare-cds-discovery"
  delay_seconds              = 0
  visibility_timeout_seconds = local.sqs.discovery_visibility_timeout_seconds
}

resource "aws_sqs_queue" "transmissions_queue" {
  name                       = "cloudflare-cds-transmissions"
  delay_seconds              = 0
  visibility_timeout_seconds = local.sqs.transmissions_visibility_timeout_seconds
}


##
# IAM Roles
##
data "aws_iam_policy_document" "cds_service_account_assume_role_policy_document" {
  statement {
    sid     = "1"
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "AWS"
      identifiers = [local.iam_roles.cloudflare_cds_account_id]
    }
  }
}

data "aws_iam_policy_document" "lambda_assume_role_policy_document" {
  statement {
    sid     = "1"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cds_service_account_iam_role" {
  name               = "cloudflare-cds-service-account-iam-role"
  assume_role_policy = data.aws_iam_policy_document.cds_service_account_assume_role_policy_document.json
  tags = {
    Name = "cloudflare-cds-service-account-iam-role"
  }
}

resource "aws_iam_role" "cds_scanner_lambda_execution_role" {
  name               = "cloudflare-cds-scanner-lambda-iam-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy_document.json
  tags = {
    Name = "cloudflare-cds-scanner-lambda-iam-role"
  }
}

resource "aws_iam_role" "cds_crawler_lambda_execution_role" {
  name               = "cloudflare-cds-crawler-lambda-iam-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy_document.json
  tags = {
    Name = "cloudflare-cds-crawler-lambda-iam-role"
  }
}

resource "aws_iam_role" "cds_control_lambda_execution_role" {
  name               = "cloudflare-cds-control-lambda-iam-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy_document.json
  tags = {
    Name = "cloudflare-cds-control-lambda-iam-role"
  }
}


##
# KMS
##
data "aws_iam_policy_document" "cds_kms_key_policy_document" {
  statement {
    sid    = "Allow cds service account to use the key for encryption only"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.cds_service_account_iam_role.arn]
    }
    actions = [
      "kms:Encrypt"
    ]
  }

  statement {
    sid    = "Enable IAM user Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

}

resource "aws_kms_key" "cds_kms_key" {
  enable_key_rotation     = true
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 7
  policy                  = data.aws_iam_policy_document.cds_kms_key_policy_document.json
  is_enabled              = true
  tags = {
    Name = "cloudflare-cds-kms-key"
  }
}

resource "aws_kms_alias" "cds_kms_key_alias" {
  name          = local.cloudflare_cds_kms_key_alias
  target_key_id = aws_kms_key.cds_kms_key.key_id
} ##
# Secrets
##
resource "aws_secretsmanager_secret" "cds_secretsmanager" {
  name                    = "cloudflare-cds-secrets"
  recovery_window_in_days = 0
  kms_key_id              = aws_kms_key.cds_kms_key.id
  tags = {
    Name = "cloudflare-cds-secrets"
  }
}

resource "aws_secretsmanager_secret_version" "cds_secrets" {
  secret_id = aws_secretsmanager_secret.cds_secretsmanager.id
  secret_string = jsonencode({
    cloudflare_api_token = var.cloudflare_api_token
  })
}

##
# Lambda
##
resource "aws_cloudwatch_log_group" "scanner_logs" {
  name              = "/aws/lambda/cloudflare-cds/cloudflare-cds-scanner"
  retention_in_days = 1
  tags = {
    Name = "cloudflare-cds-scanner-logs"
  }
}

resource "aws_cloudwatch_log_group" "crawler_logs" {
  name              = "/aws/lambda/cloudflare-cds/cloudflare-cds-crawler"
  retention_in_days = 1
  tags = {
    Name = "cloudflare-cds-crawler-logs"
  }
}

resource "aws_cloudwatch_log_group" "control_logs" {
  name              = "/aws/lambda/cloudflare-cds/cloudflare-cds-control"
  retention_in_days = 1
  tags = {
    Name = "cloudflare-cds-control-logs"
  }
}

resource "aws_lambda_function" "scanner" {
  function_name                  = "cloudflare-cds-scanner"
  role                           = aws_iam_role.cds_scanner_lambda_execution_role.arn
  image_uri                      = local.cds_scanner_ecr
  package_type                   = "Image"
  architectures                  = ["arm64"]
  timeout                        = 900
  memory_size                    = 10240
  reserved_concurrent_executions = local.lambda.scanner_concurrency

  vpc_config {
    ipv6_allowed_for_dual_stack = true
    security_group_ids          = [aws_security_group.lambda_security_group.id]
    subnet_ids                  = local.lambda_subnet_ids
  }

  environment {
    variables = merge(local.lambda.lambda_env, local.lambda.scanner_only_env)
  }

  logging_config {
    log_format            = "JSON"
    log_group             = aws_cloudwatch_log_group.scanner_logs.name
    application_log_level = var.enable_debug_logging ? "DEBUG" : "INFO"
    system_log_level      = var.enable_debug_logging ? "DEBUG" : "INFO"
  }

  tags = {
    Name = "cloudflare-cds-scanner"
  }
}

resource "aws_lambda_function" "crawler" {
  function_name                  = "cloudflare-cds-crawler"
  role                           = aws_iam_role.cds_crawler_lambda_execution_role.arn
  image_uri                      = local.cds_crawler_ecr
  package_type                   = "Image"
  architectures                  = ["arm64"]
  timeout                        = 900
  memory_size                    = 1024
  reserved_concurrent_executions = local.lambda.crawler_concurrency

  vpc_config {
    ipv6_allowed_for_dual_stack = true
    security_group_ids          = [aws_security_group.lambda_security_group.id]
    subnet_ids                  = local.lambda_subnet_ids
  }

  environment {
    variables = local.lambda.lambda_env
  }

  logging_config {
    log_format            = "JSON"
    log_group             = aws_cloudwatch_log_group.crawler_logs.name
    application_log_level = var.enable_debug_logging ? "DEBUG" : "INFO"
    system_log_level      = var.enable_debug_logging ? "DEBUG" : "INFO"
  }

  tags = {
    Name = "cloudflare-cds-crawler"
  }
}

resource "aws_lambda_function_recursion_config" "crawler_recursion_config" {
  function_name  = aws_lambda_function.crawler.function_name
  recursive_loop = "Allow"
}

resource "aws_lambda_function" "control" {
  function_name                  = local.lambda.control_function_name
  role                           = aws_iam_role.cds_control_lambda_execution_role.arn
  image_uri                      = local.cds_control_ecr
  package_type                   = "Image"
  architectures                  = ["arm64"]
  timeout                        = 900
  memory_size                    = 1024
  reserved_concurrent_executions = local.lambda.control_concurrency

  vpc_config {
    ipv6_allowed_for_dual_stack = true
    security_group_ids          = [aws_security_group.lambda_security_group.id]
    subnet_ids                  = local.lambda_subnet_ids
  }

  environment {
    variables = local.lambda.lambda_env
  }

  logging_config {
    log_format            = "JSON"
    log_group             = aws_cloudwatch_log_group.control_logs.name
    application_log_level = var.enable_debug_logging ? "DEBUG" : "INFO"
    system_log_level      = var.enable_debug_logging ? "DEBUG" : "INFO"
  }

  tags = {
    Name = "cloudflare-cds-control"
  }
}

##
# Event Bridge
##
resource "aws_cloudwatch_event_rule" "control_lambda_schedule_rule" {
  name                = "cloudflare-cds-control-schedule-rule"
  schedule_expression = local.control_schedule_minutes == 1 ? "rate(${local.control_schedule_minutes} minute)" : "rate(${local.control_schedule_minutes} minutes)"
  tags = {
    Name = "cloudflare-cds-control-schedule-rule"
  }
}

resource "aws_cloudwatch_event_target" "control_lambda_event_target" {
  rule      = aws_cloudwatch_event_rule.control_lambda_schedule_rule.name
  target_id = "cloudflare-cds-control"
  arn       = aws_lambda_function.control.arn
}

resource "aws_lambda_permission" "control_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = local.lambda.control_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.control_lambda_schedule_rule.arn
  depends_on = [
    aws_lambda_function.control
  ]
}

##
# IAM Policies
##
data "aws_iam_policy_document" "cds_sqs_consumption_iam_policy_document" {
  statement {
    sid = "AllowCloudflareCDSServiceAccountReadRemoveItems"
    actions = [
      "sqs:DeleteMessage",
      "sqs:ReceiveMessage",
      "sqs:GetQueueAttributes",
    ]

    resources = [aws_sqs_queue.scanresults_queue.arn]
  }
}

resource "aws_iam_policy" "cds_sqs_consumption_iam_policy" {
  name   = "cloudflare-cds-service-account-sqs-consumption-iam-policy"
  policy = data.aws_iam_policy_document.cds_sqs_consumption_iam_policy_document.json
  tags = {
    Name = "cloudflare-cds-service-account-sqs-consumption-iam-policy"
  }
}

data "aws_iam_policy_document" "cds_kms_encryption_iam_policy_document" {
  statement {
    sid = "AllowCloudflareCDSServiceAccountEncrypt"
    actions = [
      "kms:Encrypt"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cds_kms_encryption_iam_policy" {
  name   = "cloudflare-cds-service-account-kms-encrypt-iam-policy"
  policy = data.aws_iam_policy_document.cds_kms_encryption_iam_policy_document.json
  tags = {
    Name = "cloudflare-cds-service-account-kms-encrypt-iam-policy"
  }
}

resource "aws_iam_role_policy_attachment" "cds_service_account_iam_role_attach_sqs_consumption_policy" {
  role       = aws_iam_role.cds_service_account_iam_role.name
  policy_arn = aws_iam_policy.cds_sqs_consumption_iam_policy.arn
}

resource "aws_iam_role_policy_attachment" "cds_service_account_iam_role_attach_kms_encryption_policy" {
  role       = aws_iam_role.cds_service_account_iam_role.name
  policy_arn = aws_iam_policy.cds_kms_encryption_iam_policy.arn
}

resource "aws_iam_role_policy_attachment" "cds_scanner_lambda_attach_basic_lambda_execution_role" {
  role       = aws_iam_role.cds_scanner_lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "cds_crawler_lambda_attach_basic_lambda_execution_role" {
  role       = aws_iam_role.cds_crawler_lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "cds_control_lambda_attach_basic_lambda_execution_role" {
  role       = aws_iam_role.cds_control_lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "cds_scanner_lambda_attach_vpc_access_execution_role" {
  role       = aws_iam_role.cds_scanner_lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "cds_crawler_lambda_attach_vpc_access_execution_role" {
  role       = aws_iam_role.cds_crawler_lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "cds_control_lambda_attach_vpc_access_execution_role" {
  role       = aws_iam_role.cds_control_lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_iam_policy_document" "cds_scanner_lambda_iam_policy_document" {
  statement {
    sid       = "AllowScannerGetObject"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["*"]
  }

  statement {
    sid     = "AllowScannerSendMessages"
    effect  = "Allow"
    actions = ["sqs:SendMessage"]
    resources = [
      aws_sqs_queue.scanresults_queue.arn,
      aws_sqs_queue.scanjobs_queue.arn,
      aws_sqs_queue.transmissions_queue.arn
    ]
  }

  statement {
    sid    = "AllowScannerJobQueue"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:SendMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
    ]
    resources = [
      aws_sqs_queue.scanjobs_queue.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      aws_cloudwatch_log_group.scanner_logs.arn
    ]
  }
}

resource "aws_iam_policy" "cds_scanner_lambda_iam_policy" {
  name   = "cloudflare-cds-scanner-lambda-iam-policy"
  policy = data.aws_iam_policy_document.cds_scanner_lambda_iam_policy_document.json
  tags = {
    Name = "cloudflare-cds-scanner-lambda-iam-policy"
  }
}

data "aws_iam_policy_document" "cds_crawler_lambda_iam_policy_document" {
  statement {
    sid       = "AllowCrawlerListObjects"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["*"]
  }

  statement {
    sid     = "AllowCrawlerSendMessages"
    effect  = "Allow"
    actions = ["sqs:SendMessage"]
    resources = [
      aws_sqs_queue.scanjobs_queue.arn,
      aws_sqs_queue.discovery_queue.arn,
      aws_sqs_queue.transmissions_queue.arn
    ]
  }

  statement {
    sid    = "AllowCrawlerReadMessages"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
    ]
    resources = [
      aws_sqs_queue.discovery_queue.arn,
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      aws_cloudwatch_log_group.crawler_logs.arn
    ]
  }
}

resource "aws_iam_policy" "cds_crawler_lambda_iam_policy" {
  name   = "cloudflare-cds-crawler-lambda-iam-policy"
  policy = data.aws_iam_policy_document.cds_crawler_lambda_iam_policy_document.json
  tags = {
    Name = "cloudflare-cds-crawler-lambda-iam-policy"
  }
}

data "aws_iam_policy_document" "cds_control_lambda_iam_policy_document" {
  statement {
    sid     = "AllowControlSendMessages"
    effect  = "Allow"
    actions = ["sqs:SendMessage"]
    resources = [
      aws_sqs_queue.discovery_queue.arn,
      aws_sqs_queue.transmissions_queue.arn
    ]
  }

  statement {
    sid    = "AllowControlReadMessages"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
    ]
    resources = [
      aws_sqs_queue.discovery_queue.arn,
      aws_sqs_queue.transmissions_queue.arn
    ]
  }

  statement {
    sid    = "AllowControlGetQueueAttributes"
    effect = "Allow"
    actions = [
      "sqs:GetQueueAttributes"
    ]
    resources = [
      aws_sqs_queue.scanresults_queue.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      aws_secretsmanager_secret.cds_secretsmanager.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      aws_cloudwatch_log_group.control_logs.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cds_control_lambda_iam_policy" {
  name   = "cloudflare-cds-control-lambda-iam-policy"
  policy = data.aws_iam_policy_document.cds_control_lambda_iam_policy_document.json
  tags = {
    Name = "cloudflare-cds-control-lambda-iam-policy"
  }
}

resource "aws_iam_role_policy_attachment" "cds_scanner_lambda_attach_role" {
  role       = aws_iam_role.cds_scanner_lambda_execution_role.name
  policy_arn = aws_iam_policy.cds_scanner_lambda_iam_policy.arn
}

resource "aws_iam_role_policy_attachment" "cds_crawler_lambda_attach_role" {
  role       = aws_iam_role.cds_crawler_lambda_execution_role.name
  policy_arn = aws_iam_policy.cds_crawler_lambda_iam_policy.arn
}

resource "aws_iam_role_policy_attachment" "cds_control_lambda_attach_role" {
  role       = aws_iam_role.cds_control_lambda_execution_role.name
  policy_arn = aws_iam_policy.cds_control_lambda_iam_policy.arn
}

##
# Lambda Event Source Mapping
##
resource "aws_lambda_event_source_mapping" "crawler_event_source_mapping" {
  batch_size       = 1
  event_source_arn = aws_sqs_queue.discovery_queue.arn
  function_name    = aws_lambda_function.crawler.function_name
  tags = {
    Name = "cloudflare-cds-crawler-lambda-event-source-mapping"
  }
}

resource "aws_lambda_event_source_mapping" "scanner_event_source_mapping" {
  batch_size                         = 10
  maximum_batching_window_in_seconds = 30
  event_source_arn                   = aws_sqs_queue.scanjobs_queue.arn
  function_name                      = aws_lambda_function.scanner.function_name
  tags = {
    Name = "cloudflare-cds-scanner-lambda-event-source-mapping"
  }
}
