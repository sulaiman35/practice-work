terraform {
  backend "s3" {
    bucket = "qardio-deployments-eu-west-1"
    key    = "practice/terraform.tfstate"
    region = "eu-west-1"
  }
}

provider "aws" {}

module "vpc" {
  source      = "./vpc"
  name_prefix = var.name_prefix
}

module "rds" {
  source      = "./rds"
  name_prefix = var.name_prefix
  vpc         = module.vpc.vpc
  subnets     = module.vpc.subnets
}

module "ecs" {
  source           = "./ecs"
  name_prefix      = var.name_prefix
  vpc              = module.vpc.vpc
  subnets          = module.vpc.subnets
  ecs_cluster_name = var.ecs_cluster_name
  certificate_arn  = var.certificate_arn
  domain_name      = var.domain_name
  subdomain_url    = var.subdomain_url
}

module "task_execution_role" {
  source      = "./task-execution-role"
  name_prefix = var.name_prefix
}

module "ecr" {
  source    = "./ecr"
  ecr_repos = var.ecr_repos
}
