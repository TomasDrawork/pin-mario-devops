output "vpc_id" {
  value       = aws_vpc.main.id
  description = "El ID de la VPC creada."
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.mario_repo.repository_url
  description = "La URL del repositorio de AWS ECR para subir la imagen Docker."
}

output "alb_dns_name" {
  value       = aws_lb.mario_alb.dns_name
  description = "El DNS público del Load Balancer para acceder al juego."
}
