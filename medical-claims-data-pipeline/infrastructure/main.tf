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
    
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
  }
  
  backend "s3" {
    bucket = "medical-claims-terraform-state"
    key    = "infrastructure/terraform.tfstate"
    region = "us-east-1"
  }
}

# AWS Provider Configuration
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "medical-claims-data-pipeline"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Kubernetes Provider
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Helm Provider
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# Data sources
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# VPC and Networking
module "vpc" {
  source = "./modules/networking"
  
  environment        = var.environment
  vpc_cidr          = var.vpc_cidr
  availability_zones = var.availability_zones
  private_subnets   = var.private_subnets
  public_subnets    = var.public_subnets
}

# EKS Cluster
module "eks" {
  source = "./modules/eks"
  
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  
  node_groups = var.node_groups
  
  depends_on = [module.vpc]
}

# Kafka Cluster
module "kafka" {
  source = "./modules/kafka"
  
  environment      = var.environment
  cluster_name     = var.cluster_name
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.private_subnet_ids
  security_group_ids = [module.vpc.default_security_group_id]
  
  kafka_version   = var.kafka_version
  broker_count    = var.kafka_broker_count
  instance_type   = var.kafka_instance_type
  
  depends_on = [module.eks]
}

# Spark Cluster
module "spark" {
  source = "./modules/spark"
  
  environment      = var.environment
  cluster_name     = var.cluster_name
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.private_subnet_ids
  security_group_ids = [module.vpc.default_security_group_id]
  
  spark_version    = var.spark_version
  master_count     = var.spark_master_count
  worker_count     = var.spark_worker_count
  instance_type    = var.spark_instance_type
  
  depends_on = [module.eks]
}

# Monitoring Stack
module "monitoring" {
  source = "./modules/monitoring"
  
  environment      = var.environment
  cluster_name     = var.cluster_name
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.private_subnet_ids
  
  prometheus_enabled = var.prometheus_enabled
  grafana_enabled    = var.grafana_enabled
  alertmanager_enabled = var.alertmanager_enabled
  
  depends_on = [module.eks]
}

# Data Storage
module "storage" {
  source = "./modules/storage"
  
  environment      = var.environment
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.private_subnet_ids
  
  s3_bucket_name   = var.s3_bucket_name
  rds_enabled      = var.rds_enabled
  rds_instance_type = var.rds_instance_type
  
  depends_on = [module.vpc]
}

# Security and IAM
module "security" {
  source = "./modules/security"
  
  environment      = var.environment
  cluster_name     = var.cluster_name
  account_id       = data.aws_caller_identity.current.account_id
  
  kms_enabled      = var.kms_enabled
  secrets_enabled  = var.secrets_enabled
}
