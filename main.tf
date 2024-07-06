terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.5.1"

  backend "s3" {
    bucket = "kodecamp-capstone"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "app_server" {
  ami                    = "ami-04b70fa74e45c3917"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id, aws_security_group.allow_web_port.id]
  key_name               = "kodehauz-practice-keypair"


  user_data = file("install_docker.sh")

  tags = {
    Name = "KodeCampCapstone"
  }

}

resource "aws_default_vpc" "default" {

}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic and all outbound traffic"
  vpc_id      = aws_default_vpc.default.id

}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


resource "aws_security_group" "allow_web_port" {
  name        = "allow_web_port"
  description = "Allow inbound traffic to port 8000"
  vpc_id      = aws_default_vpc.default.id

}

resource "aws_vpc_security_group_ingress_rule" "allow_web_port" {
  security_group_id = aws_security_group.allow_web_port.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8000
  ip_protocol       = "tcp"
  to_port           = 8000
}

resource "aws_security_group" "allow_apache_port" {
  name        = "allow_apache_port"
  description = "Allow inbound traffic to port 80"
  vpc_id      = aws_default_vpc.default.id

}

resource "aws_vpc_security_group_ingress_rule" "allow_apache_port" {
  security_group_id = aws_security_group.allow_apache_port.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}
