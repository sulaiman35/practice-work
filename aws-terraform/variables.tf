variable "name_prefix" {
  description = "Name prefix of each resources"
  type        = string
  default     = "practice"
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster to be created"
  type        = string
  default     = "practice-ecs"
}

variable "ecr_repos" {
  description = "List of ecr repositories to be created"
  type        = list(string)
  default     = ["rent", "stock", "stock-frontend"]
}

variable "certificate_arn" {
  description = "the aws acm certificate arn created from AWS Certificate Manager"
  type        = string
  default     = "arn:aws:acm:eu-west-1:041027301676:certificate/b02376dc-9a03-489e-8d34-dcefa88c1b83"
}

variable "domain_name" {
  description = "the domain name you purchased should be registered as a route 53 hosted zone"
  type        = string
  default     = "test1.getgardio.com"
}

variable "subdomain_url" {
  description = "the subdomain url you'd like redirect to application load banacer"
  type        = string
  default     = "test2.getgardio.com"
}
