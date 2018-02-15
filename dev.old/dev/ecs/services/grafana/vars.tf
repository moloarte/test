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
}

variable "remote_states_bucket" {
  description = "Bucket name to store remote states and import/export outputs"
}

variable "remote_states_bucket_region" {}

variable "environment_name" {
  description = "Enviroment"
}

variable "public_key" {
  type = "map"

  default = {
    dev  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDJO3tFBHFgYWuymvZZNrEKZWwULpel1RBL3CfcfKBkmABk0zZZrP4SVY7EEs+B5J/4OVGVJi2sNcIwYAgz272IiCLRt58KGCBVzi2ve9ZyH8v8JvjinNAYrPg7eWPGsCNxy8VfJv3U6+9JFLd5LvgG96nwc4CdjmgmaC6wkRaNlgir25qNfZuVwfa/ogLl7UQ6HyHIPQaem/jQW6WcplLHL+s9obMkNVd+HoucPolYscAu7iM409VdMlHK7iS+QlDCgz/+obHZFcHHSOam9SqtJEfvKXLVN5om7DHJL4BFWGLsnMWrDtP3okk4wwtEGfbNvorcV+X+mqqTKz8geKHF vaskovskyioleksandr@PDF123-E470"
  }
}

variable "key_name" {
  default = "grafana-key"
}

variable "ssh_port" {
  default = "22"
}

variable "cluster_name" {
  default = "grafana-dev"
}
variable "signnow_zone_name" {
  description = "variable for signnow dns zone"
}
variable "instance_volume_type" {
  default     = "st1"
  description = "Instance volume type"
}

variable "instance_root_volume_size" {
  default     = "20"
  description = "Root volume size"
}

variable "instance_ebs_volume_size" {
  default     = "20"
  description = "Ebs volume size"
}

variable "instance_root_volume_delete_on_termination" {
  default     = true
  description = "Delete volume on termaintion"
}
