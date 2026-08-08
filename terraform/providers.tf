terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Opcional: Se pueden agregar etiquetas por defecto para todos los recursos
  default_tags {
    tags = {
      Environment = "Development"
      Project     = "Mario-RPG-IaC"
      ManagedBy   = "Terraform"
    }
  }
}
