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

  # Script de arranque (User Data) para instalar Docker, Docker Compose y correr la app + monitoreo
  user_data = <<-EOF
              #!/bin/bash
              # 1. Actualizar el sistema e instalar Docker y Docker Compose
              dnf update -y
              dnf install -y docker
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user

              # Instalar el plugin de Docker Compose para Amazon Linux 2023
              dnf install -y docker-compose-plugin

              # 2. Crear la estructura de directorios para la configuración de monitoreo
              mkdir -p /opt/mario-app/monitoring/prometheus
              mkdir -p /opt/mario-app/monitoring/grafana/provisioning/datasources

              # 3. Crear el archivo prometheus.yml
              cat <<'INNER_EOF' > /opt/mario-app/monitoring/prometheus/prometheus.yml
              global:
                scrape_interval: 10s

              scrape_configs:
                - job_name: 'nginx-exporter'
                  static_configs:
                    - targets: ['nginx-exporter:9113']
              INNER_EOF

              # 4. Crear el archivo datasource.yml para Grafana
              cat <<'INNER_EOF' > /opt/mario-app/monitoring/grafana/provisioning/datasources/datasource.yml
              apiVersion: 1

              datasources:
                - name: Prometheus
                  type: prometheus
                  access: proxy
                  url: http://prometheus:9090
                  isDefault: true
              INNER_EOF

              # 5. Crear el archivo docker-compose.yml adaptado para AWS (usa la imagen del ECR)
              cat <<'INNER_EOF' > /opt/mario-app/docker-compose.yml
              version: '3.8'

              services:
                mario-app:
                  image: ${aws_ecr_repository.mario_repo.repository_url}:latest
                  container_name: mario-app
                  ports:
                    - "80:80" # El balanceador ALB enviará tráfico al puerto 80 del host
                  restart: always

                nginx-exporter:
                  image: nginx/nginx-prometheus-exporter:latest
                  container_name: nginx-exporter
                  command:
                    - -nginx.scrape-uri=http://mario-app/stub_status
                  ports:
                    - "9113:9113"
                  depends_on:
                    - mario-app
                  restart: always

                prometheus:
                  image: prom/prometheus:latest
                  container_name: prometheus
                  volumes:
                    - ./monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
                  ports:
                    - "9090:9090"
                  depends_on:
                    - nginx-exporter
                  restart: always

                grafana:
                  image: grafana/grafana:latest
                  container_name: grafana
                  ports:
                    - "3000:3000" # Acceso privado via túnel SSM port-forwarding
                  volumes:
                    - ./monitoring/grafana/provisioning:/etc/grafana/provisioning
                  environment:
                    - GF_SECURITY_ADMIN_PASSWORD=admin
                  depends_on:
                    - prometheus
                  restart: always
              INNER_EOF

              # 6. Autenticarse en ECR y levantar los servicios
              aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.mario_repo.repository_url}
              
              cd /opt/mario-app
              docker compose up -d
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
