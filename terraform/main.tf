# Call VPC Module
module "vpc" {
  source              = "./modules/vpc"
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  availability_zone   = var.availability_zone
  environment         = var.environment
}

# Call Security Groups Module
module "security_groups" {
  source        = "./modules/security_groups"
  vpc_id        = module.vpc.vpc_id
  environment   = var.environment
  admin_ip_cidr = var.admin_ip_cidr
}

# Call EC2 Module
module "ec2" {
  source            = "./modules/ec2"
  public_subnet_id  = module.vpc.public_subnet_id
  private_subnet_id = module.vpc.private_subnet_id
  public_sg_id      = module.security_groups.public_sg_id
  private_sg_id     = module.security_groups.private_sg_id
  instance_type     = var.instance_type
  key_name          = var.key_name
  ami_id            = var.ami_id
  environment       = var.environment
}
