# Environment Configuration
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# AWS Configuration
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

# EKS Configuration
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "medical-claims-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "node_groups" {
  description = "EKS node group configurations"
  type = map(object({
    instance_type = string
    min_size      = number
    max_size      = number
    desired_size  = number
    disk_size     = number
  }))
  default = {
    general = {
      instance_type = "t3.medium"
      min_size      = 1
      max_size      = 3
      desired_size  = 2
      disk_size     = 20
    }
    data = {
      instance_type = "r5.large"
      min_size      = 2
      max_size      = 5
      desired_size  = 3
      disk_size     = 100
    }
  }
}

# Kafka Configuration
variable "kafka_version" {
  description = "Kafka version to deploy"
  type        = string
  default     = "3.5.1"
}

variable "kafka_broker_count" {
  description = "Number of Kafka brokers"
  type        = number
  default     = 3
}

variable "kafka_instance_type" {
  description = "EC2 instance type for Kafka brokers"
  type        = string
  default     = "t3.medium"
}

# Spark Configuration
variable "spark_version" {
  description = "Spark version to deploy"
  type        = string
  default     = "3.5.0"
}

variable "spark_master_count" {
  description = "Number of Spark master nodes"
  type        = number
  default     = 1
}

variable "spark_worker_count" {
  description = "Number of Spark worker nodes"
  type        = number
  default     = 3
}

variable "spark_instance_type" {
  description = "EC2 instance type for Spark nodes"
  type        = string
  default     = "r5.large"
}

# Monitoring Configuration
variable "prometheus_enabled" {
  description = "Enable Prometheus monitoring"
  type        = bool
  default     = true
}

variable "grafana_enabled" {
  description = "Enable Grafana dashboards"
  type        = bool
  default     = true
}

variable "alertmanager_enabled" {
  description = "Enable Alertmanager for alerting"
  type        = bool
  default     = true
}

# Storage Configuration
variable "s3_bucket_name" {
  description = "Name of S3 bucket for data lake"
  type        = string
  default     = "medical-claims-data-lake"
}

variable "rds_enabled" {
  description = "Enable RDS database"
  type        = bool
  default     = true
}

variable "rds_instance_type" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.micro"
}

# Security Configuration
variable "kms_enabled" {
  description = "Enable KMS encryption"
  type        = bool
  default     = true
}

variable "secrets_enabled" {
  description = "Enable AWS Secrets Manager"
  type        = bool
  default     = true
}

# Tags
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "medical-claims-data-pipeline"
    Owner       = "data-engineering-team"
    CostCenter  = "healthcare-analytics"
    DataClass   = "phi-sensitive"
  }
}
