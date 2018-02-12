provider "aws" {
  region = "us-east-2"
}

terraform {
    backend "s3" {}
  }

data "aws_availability_zones" "all" {}

output "elb_dns_name" {
      value = "${aws_elb.example.dns_name}"
    }

resource "aws_elb" "example" {
    name = "example-asg"
    availability_zones = ["${data.aws_availability_zones.all.names}"]
    security_groups = ["${aws_security_group.elb.id}"]
    listener {
      instance_port = "${var.http_server_port}"
      instance_protocol = "http"
      lb_port = 80
      lb_protocol = "http"
    }
    health_check {
      healthy_threshold = 2
      unhealthy_threshold = 2
      timeout = 3
      target = "HTTP:${var.http_server_port}/"
      interval = 30
    }
}

resource "aws_autoscaling_group" "example" {
    launch_configuration = "${aws_launch_configuration.example.id}"
    availability_zones = ["${data.aws_availability_zones.all.names}"]
    min_size = 2
    max_size = 5
    load_balancers= ["${aws_elb.example.id}"]
    health_check_type = "ELB"
    tag {
      key = "Name"
      value = "example-asg"
      propagate_at_launch = true
    }

}

resource "aws_security_group" "instance" {

  name = "example-policy"

  ingress {
    from_port =  "${var.http_server_port}"
    to_port = "${var.http_server_port}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group" "elb" {

  name = "example-policy-elb"

  ingress {
    from_port =  80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_launch_configuration" "example" {
  image_id = "ami-167f5773"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.instance.id}"]
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello" > index.html
              nohup busybox httpd -f -p "${var.http_server_port}" &
              EOF
  lifecycle {
    create_before_destroy = true
  }
}

variable "http_server_port" {
  description = "port to connect"
  default = "8080"
}
