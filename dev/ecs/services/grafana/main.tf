provider "aws" {
  region  = "${var.region}"
  profile = "${var.profile}"
}

terraform {
  backend "s3" {}
}

resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${lookup(var.public_key, var.environment_name)}"
}

data "terraform_remote_state" "networking" {
  backend = "s3"

  config {
    bucket  = "${var.remote_states_bucket}"
    key     = "${var.region}/core/networking/terraform.tfstate"
    region  = "${var.remote_states_bucket_region}"
    profile = "${var.profile}"
  }
}

data "terraform_remote_state" "networking_acl" {
  backend = "s3"

  config {
    bucket  = "${var.remote_states_bucket}"
    key     = "${var.region}/core/networking_acl/terraform.tfstate"
    region  = "${var.remote_states_bucket_region}"
    profile = "${var.profile}"
  }
}


//----- task definition

data "aws_ecs_task_definition" "grafana" {
  depends_on      = ["aws_ecs_task_definition.grafana"]
  task_definition = "${aws_ecs_task_definition.grafana.family}"
}
//------ template file

data "template_file" "grafana" {
  template = "${file("templates/task-definitions/grafana-ecs.json")}"

  vars {
    service_name = "${var.elastic_cluster["service_name"]}"
    balancer     = "${aws_elb.grafana.dns_name}"
    env          = "${var.environment_name}"
    region       = "${var.region}"
  }
}

// ------ Modules
module "ecs-elastic-grafana" {
  cluster_name     = "${var.elastic_cluster["service_name"]}"
  source           = "git@github.com:SignNowInc/SNTerraform-Modules.git//ecs-autoscaling"
  environment_name = "${var.environment_name}"
  key_name         = "${var.key_name}"
  region           = "${var.region}"
  cluster_cidr     = ["${data.terraform_remote_state.networking.service_private_cidr}"]
  vpc_subnets      = "${data.terraform_remote_state.networking.service_private_ids}"
  vpc_id           = "${data.terraform_remote_state.networking.vpc_id}"

  security_group_ids = ["${data.terraform_remote_state.networking_acl.sg_default}",
    "${data.terraform_remote_state.networking_acl.sg_proxy_to_service}",
  ]

  instance_volume_type                      = "${var.elastic_cluster["instance_volume_type"]}"
  instance_root_volume_size                 = "${var.elastic_cluster["instance_root_volume_size"]}"
  instance_ebs_volume_size                  = "${var.elastic_cluster["instance_ebs_volume_size"]}"
  instance_ebs_volume_delete_on_termination = "${var.elastic_cluster["instance_ebs_volume_delete_on_termination"]}"

  instance_type      = "${var.elastic_cluster["instance_type"]}"
  availability_zones = ["${data.terraform_remote_state.networking.availability_zones}"]
  min_size           = "${var.elastic_cluster["min_size"]}"
  max_size           = "${var.elastic_cluster["max_size"]}"
  desired_capacity   = "${var.elastic_cluster["desired_capacity"]}"
}

// ------ Ressources

resource "aws_elb" "grafana" {
  name     = "${var.environment_name}-${var.elastic_cluster["service_name"]}"
  internal = false

  subnets  = ["${data.terraform_remote_state.networking.proxy_public_ids}"]

  security_groups = [
    "${data.terraform_remote_state.networking_acl.sg_default}",
    "${data.terraform_remote_state.networking_acl.sg_proxy_to_service}",
    "${data.terraform_remote_state.networking_acl.sg_public_to_web}",
]


  listener = [
    {
      instance_port     = "3000"
      instance_protocol = "HTTP"
      lb_port           = "80"
      lb_protocol       = "HTTP"
    }
  ]

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 10
    target              = "TCP:3000"
    interval            = 30
  }

  tags {
    Name       = "${var.environment_name}-${var.elastic_cluster["service_name"]}"
    Env        = "${var.environment_name}"
    Managed_by = "Terraform"
  }

  connection_draining       = false
  cross_zone_load_balancing = true
}

resource "aws_ecs_service" "grafana-service" {
  name            = "${var.environment_name}-${var.elastic_cluster["service_name"]}"
  cluster         = "${module.ecs-elastic-grafana.id}"
  task_definition = "${aws_ecs_task_definition.grafana.family}"

  desired_count                      = "${var.elastic_cluster["desired_capacity"]}"
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 50

  load_balancer {
    elb_name       = "${aws_elb.grafana.id}"
    container_name = "${var.environment_name}-${var.elastic_cluster["service_name"]}"
    container_port = 3000
  }
}

resource "aws_ecs_task_definition" "grafana" {
  family                = "${var.environment_name}-${var.elastic_cluster["service_name"]}"
  container_definitions = "${data.template_file.grafana.rendered}"

  volume {
    name      = "root"
    host_path = "/"
  }

  volume {
    name      = "grafana"
    host_path = "/var/lib/grafana"
  }
}
