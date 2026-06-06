# Fetch the latest Amazon Linux 2 AMI if no custom AMI is provided
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

locals {
  ami_id = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux_2.id
}

# Public EC2 Instance (Bastion Host)
resource "aws_instance" "public_ec2" {
  ami                         = local.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.public_sg_id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  tags = {
    Name        = "${var.environment}-public-ec2"
    Environment = var.environment
    Type        = "public"
  }
}

# Private EC2 Instance
resource "aws_instance" "private_ec2" {
  ami                         = local.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.private_subnet_id
  vpc_security_group_ids      = [var.private_sg_id]
  key_name                    = var.key_name
  associate_public_ip_address = false

  tags = {
    Name        = "${var.environment}-private-ec2"
    Environment = var.environment
    Type        = "private"
  }
}
