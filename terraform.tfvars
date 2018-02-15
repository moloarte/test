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

  terraform {
    extra_arguments "common_var" {
      commands = [
        "apply",
        "plan",
        "import",
        "push",
        "destroy",
        "refresh",
        "apply-all",
        "destroy-all"

      ]



      arguments = [
           "-var-file=${get_parent_tfvars_dir()}/common.tfvars"
      ]

    }
  }

}
