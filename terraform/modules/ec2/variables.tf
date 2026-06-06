variable "public_subnet_id" {
  description = "The ID of the public subnet to deploy the public instance"
  type        = string
}

variable "private_subnet_id" {
  description = "The ID of the private subnet to deploy the private instance"
  type        = string
}

variable "public_sg_id" {
  description = "Security group ID for the public instance"
  type        = string
}

variable "private_sg_id" {
  description = "Security group ID for the private instance"
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Key pair name to associate with the instances"
  type        = string
}

variable "environment" {
  description = "The environment name for tagging"
  type        = string
  default     = "dev"
}

variable "ami_id" {
  description = "Custom AMI ID. If empty, the latest Amazon Linux 2 AMI will be used."
  type        = string
  default     = ""
}
