provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "test_remote_state" {
    bucket = "signnow-terraform-test-remote-state"
    versioning {
      enabled = true
    }
    lifecycle {
      prevent_destroy = true
    }
  }
