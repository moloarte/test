variable "region" {
  description = "Region to deploy the Consul Cluster into"
  default     = "us-east-1"
}

variable "amis" {
  default = {
    us-east-1 = "ami-eca289fb"
    us-west-1 = "ami-9fadf8ff"
  }
}

variable "health_check_grace_period" {
  default     = "300"
  description = "Time after instance comes into service before checking health"
}

variable "profile" {
  description = "profile to use aws creds"
  # default = "signnow_dev"
}

variable "remote_states_bucket" {
  description = "Bucket name to store remote states and import/export outputs"
  # default = "terraform-signnow-dev-remote-states"
}

variable "remote_states_bucket_region" {
  # default = "us-east-2"
}

variable "public_key" {
  type = "map"

  default = {
    prod = ""
    dev  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDJO3tFBHFgYWuymvZZNrEKZWwULpel1RBL3CfcfKBkmABk0zZZrP4SVY7EEs+B5J/4OVGVJi2sNcIwYAgz272IiCLRt58KGCBVzi2ve9ZyH8v8JvjinNAYrPg7eWPGsCNxy8VfJv3U6+9JFLd5LvgG96nwc4CdjmgmaC6wkRaNlgir25qNfZuVwfa/ogLl7UQ6HyHIPQaem/jQW6WcplLHL+s9obMkNVd+HoucPolYscAu7iM409VdMlHK7iS+QlDCgz/+obHZFcHHSOam9SqtJEfvKXLVN5om7DHJL4BFWGLsnMWrDtP3okk4wwtEGfbNvorcV+X+mqqTKz8geKHF vaskovskyioleksandr@PDF123-E470"
  }
}

variable "key_name" {
  default = "grafana-key"
}

variable "environment_name" {
  description = "Enviroment"
  # default = "dev"
}

variable "main_domain" {
  default = "signnow.com"
}

variable "ssl_certificate_id" {
  description = "Default params for Zabbix Server or Agents"

  type = "map"

  default {
    signnow.xyz = "arn:aws:acm:us-east-1:947694726085:certificate/8b3cecc9-8ba8-4c19-8dc9-8838e3be927f" //DEV AWS ACCOUNT
    signnow.com = "arn:aws:acm:us-east-1:853665720675:certificate/5755d730-a758-49e7-8428-d27b52b28bdb" //PROD AWS ACCOUNT
  }
}

# variable "signnow_zone_name" {
#   description = "variable for signnow dns zone"
# }

variable "elastic_cluster" {
  description = "Default params for the elastic cluster"

  type = "map"

  default {
    service_name                              = "grafana"
    instance_type                             = "t1.micro"
    instance_volume_type                      = "gp2"
    instance_root_volume_size                 = 20
    instance_ebs_volume_size                  = 20
    instance_ebs_volume_delete_on_termination = true
    min_size                                  = 1
    max_size                                  = 1
    desired_capacity                          = 1
  }
}
