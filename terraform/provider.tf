
# //////////////////////////////
#          Providers
# //////////////////////////////
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.39.0"
    }
  }
}

variable "cluster_version" {
  default = "1.22"
}


# Configure the AWS Provider
provider "aws" {
  region = "eu-west-2"
}
