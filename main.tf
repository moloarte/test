provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "example" {
  ami = "ami-167f5773"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
  tags {
    Name = "examle"
  }
}

resource "aws_security_group" "instance" {

  name = "example-policy"

  ingress {
    from_port =  8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
