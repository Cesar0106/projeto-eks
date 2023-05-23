locals {
  cluster_name = "my-web-app-cluster"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway  = true

}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.1.0"

  cluster_name = local.cluster_name
  cluster_version = "1.23" 
  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  node_groups = {
    eks_nodes = {
      desired_capacity = 2
      max_capacity     = 10
      min_capacity     = 1

      instance_type = "t3.medium"
      key_name      = "my-keypair" # substitua pelo nome da sua chave

      additional_tags = {
        Environment = "dev"
        Terraform = "true"
        Name        = "eks-worker-node"
}
}
}
}
