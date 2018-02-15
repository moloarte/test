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

module "ecs-service-cluster" {
  cluster_name     = "${var.cluster_service["service_name"]}"
  source           = "git@github.com:SignNowInc/SNTerraform-Modules.git//ecs-autoscaling"
  environment_name = "${var.environment_name}"
  key_name         = "${var.key_name}"
  region           = "${var.region}"

  availability_zones = ["${data.terraform_remote_state.networking.availability_zones}"]
  cluster_cidr       = ["${data.terraform_remote_state.networking.service_private_cidr}"]
  vpc_subnets        = "${data.terraform_remote_state.networking.service_private_ids}"
  vpc_id             = "${data.terraform_remote_state.networking.vpc_id}"

  security_group_ids = ["${data.terraform_remote_state.networking_acl.sg_default}",
    "${data.terraform_remote_state.networking_acl.sg_proxy_to_service}",
    "${data.terraform_remote_state.networking_acl.sg_allow_all_in}",
  ]

  instance_volume_type                      = "${var.cluster_service["instance_volume_type"]}"
  instance_root_volume_size                 = "${var.cluster_service["instance_root_volume_size"]}"
  instance_ebs_volume_size                  = "${var.cluster_service["instance_ebs_volume_size"]}"
  instance_ebs_volume_delete_on_termination = "${var.cluster_service["instance_ebs_volume_delete_on_termination"]}"
  instance_type                             = "${var.cluster_service["instance_type"]}"
  min_size                                  = "${var.cluster_service["min_size"]}"
  max_size                                  = "${var.cluster_service["max_size"]}"
  desired_capacity                          = "${var.cluster_service["desired_capacity"]}"
}

module "ecs-zabbix-agent" {
  source             = "git@github.com:SignNowInc/SNTerraform-Modules.git//ecs-zabbix-agent"
  region             = "${var.region}"
  env                = "${var.environment_name}"
  ecs_cluster_id     = "${module.ecs-service-cluster.id}"
  desired_capacity   = "${var.cluster_service["desired_capacity"]}"
  zabbix_server_host = "zabbix-proxy.${var.signnow_zone_name}"
}

resource "aws_elb" "consul-bootstrap" {
  name = "${var.environment_name}-consul-bootstrap"

  subnets  = ["${data.terraform_remote_state.networking.proxy_public_ids}"]
  internal = true

  security_groups = [
    "${data.terraform_remote_state.networking_acl.sg_default}",
    "${data.terraform_remote_state.networking_acl.sg_proxy_to_service}",
    "${data.terraform_remote_state.networking_acl.sg_public_to_consul}",
    "${data.terraform_remote_state.networking_acl.sg_public_to_web}",
  ]

  listener {
    instance_port     = 8500
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port     = 8301
    instance_protocol = "tcp"
    lb_port           = 8301
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 8500
    instance_protocol = "http"
    lb_port           = 8500
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    target              = "TCP:8500"
    interval            = 10
  }

  connection_draining = false

  tags {
    Name = "${var.environment_name}-consul-bootstrap"
    Env  = "${var.environment_name}"
  }
}

resource "aws_ecs_task_definition" "consul-bootstrap" {
  family                = "${var.environment_name}-consul-bootstrap"
  container_definitions = "${data.template_file.consul-bootstrap.rendered}"

  volume {
    name      = "consuldata"
    host_path = "/mnt/data/consul"
  }
}

resource "aws_ecs_task_definition" "consul-server" {
  family                = "${var.environment_name}-consul-server"
  container_definitions = "${data.template_file.consul-server.rendered}"

  volume {
    name      = "consuldata"
    host_path = "/mnt/data/consul"
  }
}

resource "aws_ecs_service" "consul-bootstrap" {
  name            = "${var.environment_name}-consul-bootstrap"
  cluster         = "${module.ecs-service-cluster.id}"
  task_definition = "${aws_ecs_task_definition.consul-bootstrap.family}:${max("${aws_ecs_task_definition.consul-bootstrap.revision}", "${data.aws_ecs_task_definition.consul-bootstrap.revision}")}"
  desired_count   = "1"
  iam_role        = "${module.ecs-service-cluster.iam_role}"

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  load_balancer {
    elb_name       = "${aws_elb.consul-bootstrap.id}"
    container_name = "${var.environment_name}-consul-bootstrap"
    container_port = 8500
  }
}

resource "aws_ecs_service" "consul-server-service" {
  name            = "${var.environment_name}-consul-server"
  cluster         = "${module.ecs-service-cluster.id}"
  task_definition = "${aws_ecs_task_definition.consul-server.family}:${max("${aws_ecs_task_definition.consul-server.revision}", "${data.aws_ecs_task_definition.consul-server.revision}")}"

  desired_count                      = "4"
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 50
}

//----- DNS

resource "aws_route53_record" "consul-cl01" {
  zone_id = "${data.terraform_remote_state.route53.signnow_zone_id}"
  name    = "consul-cl01.${var.signnow_zone_name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["bastion.${var.signnow_zone_name}"]
}
