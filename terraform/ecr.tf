# Registro ECR para almacenar la imagen Docker de Mario RPG
resource "aws_ecr_repository" "mario_repo" {
  name                 = "${var.project_name}-repo"
  image_tag_mutability = "MUTABLE" # Permite sobrescribir el tag 'latest' en cada despliegue

  # Escaneo automático de vulnerabilidades al subir la imagen
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-repo"
  }
}
