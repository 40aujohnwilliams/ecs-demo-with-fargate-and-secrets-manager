
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"
  name    = "${local.project-name}-${local.environment-name}"
  azs     = local.availability-zones

  cidr = local.base-cidr-block

  # Database Variables
  create_database_subnet_group           = false

  # DNS Variables
  enable_dns_hostnames = true
  enable_dns_support   = true

  # IPv6 Variables
  enable_ipv6 = false

  # Log Variables
  enable_flow_log                                 = false

  # NAT Variables
  enable_nat_gateway = true
  single_nat_gateway = true

  # Subnet Variables
  public_subnets   = local.public-subnets
  private_subnets  = local.private-subnets

  tags = local.tags
}

