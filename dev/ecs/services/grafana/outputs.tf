
output "elb-grafana-dns" {
  value = "${aws_elb.grafana.dns_name}"
}
