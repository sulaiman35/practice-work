# Azure Web App Service Hosting terraform module

This Terraform Code is written for practical test to submit.

## Usage

To use this Terraform code:

Please check below shared variables and they need to be filled at the time of `terraform plan`, a separate `tfvars.example` file is also created for assistance.
Example module usage:

```hcl
  Simple command to execute for deployment: `terraform apply -auto-approve -var-file="tfvars.example"`

  environment    = "dev"
  project_name = "test"
  azure_location = "eastus"
  service_log_ipv4_allow_list = ["80.60.130.136", "80.60.130.137"]
  existing_resource_group = "sulaiman-test1_group"
  virtual_network_address_space = "172.16.0.0/12"

  default     = {
    environment = "Dev"
    cloud       = "azure"
    team        = "qa"
  }

  launch_in_vnet                = true
  existing_virtual_network      = "vnet-id" # setting this will launch resources into this existing virtual network, rather than creating a new one.
  existing_resource_group       = "resource-id" # setting this will launch resources into this existing resource group, rather than creating a new one.
  virtual_network_address_space = "172.16.0.0/12"

  service_plan_sku      = "S1"
  service_plan_os       = "Windows"
  service_stack         = "dotnet"
  service_stack_version = "v4.0"
  service_worker_count  = 1
  service_app_settings  = {
    environment = "Dev"
    cloud       = "azure"
    team        = "qa"
  }
  service_health_check_path                 = "/"
  service_health_check_eviction_time_in_min = 5
  enable_service_logs                       = true
  service_log_level                         = "Informational"
  service_log_retention                     = 30

```