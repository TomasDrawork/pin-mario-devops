# 1. Application Load Balancer Público
resource "aws_lb" "mario_alb" {
  name               = "${var.project_name}-alb"
  internal           = false # Es un balanceador público de cara a Internet
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id] # Ubicado en las subredes públicas

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# 2. Grupo de Destino (Target Group) para la EC2
resource "aws_lb_target_group" "mario_tg" {
  name        = "${var.project_name}-tg"
  port        = 80 # Puerto donde escucha el contenedor Nginx en la EC2
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  # Configuración del Health Check para determinar si la app está en línea
  health_check {
    enabled             = true
    path                = "/"
    port                = "80"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}

# 3. Listener HTTP del ALB
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.mario_alb.arn
  port              = "80"
  protocol          = "HTTP"

  # Acción por defecto: reenviar el tráfico al target group
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mario_tg.arn
  }
}
