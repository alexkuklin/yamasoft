module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0" # Use a stable, recent version

  name = "test" 
  cidr = "10.0.0.0/16"

  # Define subnets across 3 Availability Zones
  azs             = data.aws_availability_zones.available.names
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  # EKS nodes should be in private subnets with NAT Gateway for outbound internet access
  enable_nat_gateway = true
  single_nat_gateway = true

  # Tags required by the EKS module to find the subnets
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}
