provider "aws" {
   region = "us-east-2"
 }

terraform {
    backend "s3" {}
  }

module "wb_cluster" {
  source = "../../modules/services/wb/"
}
