terragrunt = {
  remote_state {
    backend = "s3"
    config {
      bucket         = "signnow-terraform-test-remote-state"
      key            = "${path_relative_to_include()}/terraform.tfstate"
      region         = "us-east-2"
      encrypt        = true
      dynamodb_table = "signnow-test-dyno-table"
    }
  }
}
