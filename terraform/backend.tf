
terraform {
  backend "s3" {
    bucket  = "eks-cluster-dev"
    key     = "eks-cluster-mono/terraform.tfstate"
    region  = "eu-west-2"
    acl     = "private"
    encrypt = true
  }
}
