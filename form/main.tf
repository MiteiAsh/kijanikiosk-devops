terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_security_group" "kijanikiosk" {
  name        = "kijanikiosk-sg"
  description = "Security group for KijaniKiosk servers"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "kijani-key"
  public_key = file("~/.ssh/kijani-key.pub")
}

module "app_server" {
  for_each = {
    api      = { name = "api-server", role = "api" }
    payments = { name = "payments-server", role = "payments" }
    logs     = { name = "logs-server", role = "logs" }
  }
  
  source = "./modules/app_server"
  
  server_name    = each.value.name
  instance_type  = "t3.micro"
  ami_id         = data.aws_ami.ubuntu.id
  subnet_id      = var.subnet_id
  security_group_ids = [aws_security_group.kijanikiosk.id]
  key_name       = aws_key_pair.deployer.key_name
  environment    = "staging"
}

output "api_server_ip" {
  value = module.app_server["api"].public_ip
}

output "payments_server_ip" {
  value = module.app_server["payments"].public_ip
}

output "logs_server_ip" {
  value = module.app_server["logs"].public_ip
}
