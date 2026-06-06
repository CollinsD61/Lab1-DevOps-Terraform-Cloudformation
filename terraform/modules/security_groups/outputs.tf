output "public_sg_id" {
  description = "The ID of the security group for the public EC2 instance"
  value       = aws_security_group.public_ec2.id
}

output "private_sg_id" {
  description = "The ID of the security group for the private EC2 instance"
  value       = aws_security_group.private_ec2.id
}
