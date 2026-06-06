# Security Group for Public EC2 (Bastion / Public access)
resource "aws_security_group" "public_ec2" {
  name        = "${var.environment}-public-ec2-sg"
  description = "Security group for public EC2 instance (Bastion)"
  vpc_id      = var.vpc_id

  # Inbound rules
  ingress {
    description = "Allow SSH from Admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip_cidr]
  }

  # Outbound rules
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-public-ec2-sg"
    Environment = var.environment
  }
}

# Security Group for Private EC2 (Private access only)
resource "aws_security_group" "private_ec2" {
  name        = "${var.environment}-private-ec2-sg"
  description = "Security group for private EC2 instance"
  vpc_id      = var.vpc_id

  # Inbound rules (Allow SSH only from the Public Security Group)
  ingress {
    description     = "Allow SSH only from Public EC2 SG"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public_ec2.id]
  }

  # Outbound rules
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-private-ec2-sg"
    Environment = var.environment
  }
}
