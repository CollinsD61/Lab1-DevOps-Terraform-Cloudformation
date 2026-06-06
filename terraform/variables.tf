variable "aws_region" {
  description = "The AWS Region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name used for naming resources"
  type        = string
  default     = "lab"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone" {
  description = "Availability zone for both subnets"
  type        = string
  default     = "us-east-1a"
}

variable "admin_ip_cidr" {
  description = "Your local IP CIDR block allowed to access the Bastion host via SSH (e.g. 203.0.113.50/32)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the key pair for SSH access"
  type        = string
}

variable "ami_id" {
  description = "Specific AMI ID if override is needed"
  type        = string
  default     = ""
}
