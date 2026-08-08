# 1. Obtener la AMI de Amazon Linux 2023 más reciente
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 2. Creación de la instancia EC2 en la subred privada
resource "aws_instance" "mario_app" {
  ami                  = data.aws_ami.al2023.id
  instance_type        = var.instance_type
  subnet_id            = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  # Script de arranque (User Data) para instalar Docker y correr el contenedor
  user_data = <<-EOF
              #!/bin/bash
              # 1. Actualizar el sistema
              dnf update -y

              # 2. Instalar Docker
              dnf install -y docker
              systemctl start docker
              systemctl enable docker

              # 3. Dar permisos al usuario del sistema
              usermod -aG docker ec2-user

              # 4. Iniciar sesión en AWS ECR
              # Nota: Amazon Linux 2023 ya incluye aws-cli preinstalado
              aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.mario_repo.repository_url}

              # 5. Descargar la imagen del repositorio
              docker pull ${aws_ecr_repository.mario_repo.repository_url}:latest

              # 6. Ejecutar el contenedor escuchando en el puerto 80
              docker run -d --name mario-rpg -p 80:80 --restart always ${aws_ecr_repository.mario_repo.repository_url}:latest
              EOF

  # metadata_options para forzar el uso de IMDSv2 (buena práctica de seguridad)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tags = {
    Name = "${var.project_name}-ec2-instance"
  }
}

# 3. Registro de la Instancia EC2 en el Target Group del ALB
resource "aws_lb_target_group_attachment" "mario_attachment" {
  target_group_arn = aws_lb_target_group.mario_tg.arn
  target_id        = aws_instance.mario_app.id
  port             = 80
}
