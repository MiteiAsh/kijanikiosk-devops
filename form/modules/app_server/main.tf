resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  key_name               = var.key_name
  
  tags = {
    Name = var.server_name
  }
}

resource "aws_eip" "this" {
  instance = aws_instance.this.id
  domain   = "vpc"
}

output "public_ip" {
  value = aws_eip.this.public_ip
}
