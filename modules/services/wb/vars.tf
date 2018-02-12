variable "http_server_port" {
  description = "port to connect"
  default = "8080"
}

variable "ssh_port" {
  description = "port to connect"
  default = "22"
}

variable "ami" {
  default = "ami-167f5773"
}

variable "server_text" {
  default = "SDSDSLGFDFJJ"
}

variable "instance_type" {
  description = "t2.micro instance"
}

variable "min_size" {
  description = "min instances"
}

variable "max_size" {
  description = "max instances"
}
