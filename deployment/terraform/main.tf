terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.27"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    healthcare_nodes = {
      name = "healthcare-nodes"

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      min_size     = 2
      max_size     = 10
      desired_size = 3

      k8s_labels = {
        Environment = var.environment
        Application = "healthcare-system"
      }
    }
  }

  tags = {
    Environment = var.environment
    Project     = "healthcare-microservices"
  }
}

# VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.cluster_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# RDS Database
resource "aws_db_instance" "healthcare_db" {
  allocated_storage    = 20
  max_allocated_storage = 100
  storage_type         = "gp2"
  engine              = "postgres"
  engine_version      = "15.4"
  instance_class      = "db.t3.micro"
  identifier          = "${var.cluster_name}-db"
  username            = var.db_username
  password            = var.db_password
  parameter_group_name = "default.postgres15"
  skip_final_snapshot = true

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.healthcare.name

  tags = {
    Name        = "${var.cluster_name}-database"
    Environment = var.environment
  }
}

# ElastiCache Redis
resource "aws_elasticache_subnet_group" "healthcare" {
  name       = "${var.cluster_name}-redis-subnet"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_elasticache_cluster" "healthcare_redis" {
  cluster_id           = "${var.cluster_name}-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.healthcare.name
  security_group_ids   = [aws_security_group.redis.id]
}
