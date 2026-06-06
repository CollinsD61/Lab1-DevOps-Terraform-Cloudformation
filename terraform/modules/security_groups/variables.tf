variable "vpc_id" {
  description = "The ID of the VPC where security groups will be created"
  type        = string
}

variable "environment" {
  description = "The environment name for tagging"
  type        = string
  default     = "dev"
}

variable "admin_ip_cidr" {
  description = "The CIDR block allowed to SSH into the public EC2 instance (e.g. 203.0.113.50/32)"
  type        = string
  default     = "0.0.0.0/0" # Allow all by default, but should be restricted in tfvars
}
