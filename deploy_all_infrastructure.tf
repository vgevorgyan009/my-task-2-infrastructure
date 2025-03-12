terraform {
  required_version = ">= 0.12"
  backend "s3" {
    bucket = "myapp-tf-s3-bucket69"
    key    = "mytest3/state.tfstate"
    region = "eu-west-3"
  }
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "azs" {}

module "myapp-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name            = "myapp-vpc"
  cidr            = var.vpc_cidr_block
  private_subnets = var.private_subnet_cidr_blocks
  public_subnets  = var.public_subnet_cidr_blocks
  azs             = data.aws_availability_zones.azs.names

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
    "kubernetes.io/role/elb"                  = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb"         = 1
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.17.2"

  cluster_name                   = "myapp-eks-cluster"
  cluster_version                = "1.31"
  cluster_endpoint_public_access = true

  subnet_ids = module.myapp-vpc.private_subnets
  vpc_id     = module.myapp-vpc.vpc_id

  tags = {
    environment = "development"
    application = "myapp"
  }

  eks_managed_node_groups = {
    dev = {
      min_size     = 3
      max_size     = 6
      desired_size = 3

      instance_types = ["t3.small"]
    }
  }
}

data "aws_iam_role" "eks_worker_role" {
  name = element(split("/", module.eks.eks_managed_node_groups[keys(module.eks.eks_managed_node_groups)[0]].iam_role_arn), 1)
}

resource "aws_iam_policy" "cluster_autoscaler_policy" {
  name        = "ClusterAutoscalerPolicy"
  path        = "/"
  description = "Custom IAM policy for Cluster Autoscaler"
  policy      = file("./policy.json")
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler_attach" {
  policy_arn = aws_iam_policy.cluster_autoscaler_policy.arn
  role       = data.aws_iam_role.eks_worker_role.name
}

module "Argocd_and_Ingress_and_ClusterAutoscaler_ExternalSecrets" {
  source           = "./my-modules/terraform_install_argocd_eks"
  eks_cluster_name = "myapp-eks-cluster"
  chart_version    = "5.46.2"
  eks_dependency   = module.eks
  region           = var.region
}

/*
module "argocd_application" {
  source             = "./my-modules/terraform_create_argocd_application_eks"
  eks_cluster_name   = "myapp-eks-cluster"
  git_source_path    = "MyAppHelmChart"
  git_source_repoURL = "https://github.com/vgevorgyan009/my-task-2-infrastructure.git"
}
*/
