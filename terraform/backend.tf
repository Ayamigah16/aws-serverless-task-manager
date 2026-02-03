terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "task-manager-terraform-state-eu-west-1"
    key            = "sandbox/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "task-manager-terraform-locks"
  }
}
