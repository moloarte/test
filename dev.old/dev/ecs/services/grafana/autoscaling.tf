data "aws_availability_zones" "all" {}

resource "aws_autoscaling_group" "grafana" {
    launch_configuration = "${aws_launch_configuration.grafana.id}"
    availability_zones = ["${data.aws_availability_zones.all.names}"]
    min_size = "${var.min_size}"
    max_size = "${var.max_size}"
    load_balancers= ["${aws_elb.example.id}"]
    health_check_type = "EC2"

tag {
    key                 = "Env"
    value               = "${var.environment_name}"
    propagate_at_launch = true
    }

tag {
    key                 = "Name"
    value               = "${var.environment_name}-${var.cluster_name}"
  propagate_at_launch = true
    }

tag {
    key                 = "Cluster"
    value               = "${var.cluster_name}"
    propagate_at_launch = true
      }
lifecycle {
      create_before_destroy = true
    }
}
resource "aws_launch_configuration" "grafana" {
  name_prefix = "${var.environment_name}-${var.cluster_service["service_name"]}"
  image_id = "${var.ami}"
  instance_type = "${var.instance_type}"
  security_groups = ["${aws_security_group.instance.id}"]
  # user_data = <<-EOF
  #             #!/bin/bash
  #             echo "Hello" > index.html
  #             nohup busybox httpd -f -p "${var.http_server_port}" &
  #             EOF
  lifecycle {
    create_before_destroy = true
  }
}
