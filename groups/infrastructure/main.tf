terraform {
  required_version = ">= 1.3, < 2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = ">= 5.0, < 6.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
}

terraform {
  backend "s3" {}
}

module "ecs_cluster" {
  source = "git@github.com:companieshouse/terraform-modules//aws/ecs/ecs-cluster?ref=1.0.412"

  environment = var.environment
  name_prefix = local.name_prefix
  stack_name  = local.stack_name
  subnet_ids  = local.application_subnet_ids
  vpc_id      = data.aws_vpc.vpc.id

  ec2_key_pair_name = var.ec2_key_pair_name
  ec2_instance_type = var.ec2_instance_type
  ec2_image_id      = var.ec2_image_id

  asg_max_instance_count     = var.asg_max_instance_count
  asg_min_instance_count     = var.asg_min_instance_count
  asg_desired_instance_count = var.asg_desired_instance_count

  scaledown_schedule     = var.asg_scaledown_schedule
  scaleup_schedule       = var.asg_scaleup_schedule

  enable_container_insights   = var.enable_container_insights
  notify_topic_slack_endpoint = local.notify_topic_slack_endpoint

  default_tags = merge(
    module.iac_tags.tags,
    module.owner_tags.tags,
  )
}

moved {
  from = module.ecs-cluster
  to   = module.ecs_cluster
}

module "iac_tags" {
  source = "git@github.com:companieshouse/terraform-modules//aws/tagging/iac?ref=tags/1.0.412"

  group           = "infrastructure"
  source_code_url = "https://github.com/companieshouse/identity-service-stack"
}

module "owner_tags" {
  source = "git@github.com:companieshouse/terraform-modules//aws/tagging/owner?ref=tags/1.0.412"

  platform_owner    = "platform"
}
