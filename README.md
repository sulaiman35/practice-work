# Practice Work 

## Directory

- `react-and-spring-data-rest/` Contains code Front End and Backend
- `terraforn` contains the infrastructure as a code
- `.gitlab-ci` Contains CI/CD Pipeline

## Setup
### Infrastrcuture
To start working with the application you must setup aws, terraform, as Infrastructure (ECR, ECS, RDS, VPC) need to be created first
Deployments are done in multi region backend and frontend ecs.

### AWS
- Create an AWS account
- Create an AWS IAM user for terraform with the AdministratorAccess and keep the aws key and aws secret for later
- Create the bucket `ANY-NAME` with default configuration and update terraform `terraform/main.tf` bucketname and region

### Terraform
- Check terraform folder README.md

## To deploy
- To Deploy `.gitlab-ci-backend.yml` and `.gitlab-ci-frontend.yml` files are there.
- Create `dockerfile` for FrontEnd and `dockerfile_java` for Java Application

### Pending
- Seprating Backend and Frontend Application.

## Logs
On cloudwatch, you will find all the applications logs split between frontend and backend

## Security
For security Sonarqube can be used but as application was supporting so didn't placed
For git code security used `Talisman` for Git scanner

## Information
The infrastucture will scale between 1 and 5 servers depending of the cpu usage. 

You can deploy on another region by adding a new provider on `terraform/main.tf` exemple :
```
provider "aws" {
  alias  = "eu-west-1"
  region = "eu-west-1"
}

module "eu-west-1" {
  source = "./aws"
  name   = "eu-west-1"
  providers = {
    aws = "aws.eu-west-1"
  }
  availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  database_availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}
```

And you can create a new module for GCP or azure if you want to deploy on multi cloud services.
