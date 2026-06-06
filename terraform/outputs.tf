output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "The ID of the public subnet"
  value       = module.vpc.public_subnet_id
}

output "private_subnet_id" {
  description = "The ID of the private subnet"
  value       = module.vpc.private_subnet_id
}

output "public_security_group_id" {
  description = "The ID of the public EC2 security group"
  value       = module.security_groups.public_sg_id
}

output "private_security_group_id" {
  description = "The ID of the private EC2 security group"
  value       = module.security_groups.private_sg_id
}

output "public_instance_id" {
  description = "The ID of the public EC2 instance"
  value       = module.ec2.public_instance_id
}

output "public_instance_public_ip" {
  description = "The public IP address of the public EC2 instance"
  value       = module.ec2.public_instance_public_ip
}

output "private_instance_id" {
  description = "The ID of the private EC2 instance"
  value       = module.ec2.private_instance_id
}

output "private_instance_private_ip" {
  description = "The private IP address of the private EC2 instance"
  value       = module.ec2.private_instance_private_ip
}
