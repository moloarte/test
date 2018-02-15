resource "aws_launch_configuration" "grafana" {
  name_prefix = "${var.environment_name}-${var.cluster_name}"
  image_id = "${var.ami}"
  instance_type = "${var.instance_type}"
  security_groups = ["${aws_security_group.instance.id}"]
  lifecycle {
    create_before_destroy = true
  }
}
