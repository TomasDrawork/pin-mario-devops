# 1. Grupo de Seguridad para el Application Load Balancer (Público)
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Permite acceso HTTP publico al balanceador"
  vpc_id      = aws_vpc.main.id

  # Entrada: Puerto HTTP 80 desde cualquier origen
  ingress {
    description      = "HTTP desde el exterior"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Salida: Permitir todo el tráfico saliente
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# 2. Grupo de Seguridad para la Instancia EC2 (Privada)
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Permite trafico entrante unicamente desde el ALB"
  vpc_id      = aws_vpc.main.id

  # Entrada: Puerto 80 desde el Security Group del ALB únicamente
  ingress {
    description     = "HTTP desde el ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Salida: Permitir todo el tráfico saliente (necesario para NAT Gateway)
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}
