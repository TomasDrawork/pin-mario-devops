variable "aws_region" {
  type        = string
  description = "La región de AWS donde se desplegarán los recursos."
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Nombre del proyecto, utilizado para nombrar recursos."
  default     = "mario-rpg"
}

variable "vpc_cidr" {
  type        = string
  description = "El bloque CIDR para la VPC principal."
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Bloques CIDR para las subredes públicas (se requieren al menos 2 en diferentes AZs para el ALB)."
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidr" {
  type        = string
  description = "Bloque CIDR para la subred privada donde residirá la EC2."
  default     = "10.0.10.0/24"
}

variable "instance_type" {
  type        = string
  description = "El tipo de instancia de EC2 para correr el contenedor."
  default     = "t3.micro"
}
