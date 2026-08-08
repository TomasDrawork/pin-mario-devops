# Resumen Técnico de Handover - Proyecto Integrador 1

Este documento contiene el estado actual del **Proyecto Integrador 1 (Super Mario RPG)**, estructurado para transferir el contexto técnico a otro asistente de IA.

---

## 📁 Estructura del Repositorio

A continuación se muestra la estructura actual de los archivos en el repositorio:

- [.github/](file:///home/tomas-drago/Pin%20final/.github)
  - [workflows/](file:///home/tomas-drago/Pin%20final/.github/workflows)
    - [cicd.yml](file:///home/tomas-drago/Pin%20final/.github/workflows/cicd.yml) — Pipeline de GitHub Actions (Análisis, Build y Push).
- [mario-rpg/](file:///home/tomas-drago/Pin%20final/mario-rpg) — Código de la aplicación web (HTML5/Canvas).
  - [Dockerfile](file:///home/tomas-drago/Pin%20final/mario-rpg/Dockerfile) — Empaquetado del servidor web con Nginx.
  - [index.html](file:///home/tomas-drago/Pin%20final/mario-rpg/index.html) — Tablero del juego.
  - [script.js](file:///home/tomas-drago/Pin%20final/mario-rpg/script.js) — Lógica de juego, físicas y sonido.
  - [style.css](file:///home/tomas-drago/Pin%20final/mario-rpg/style.css) — Estilos retro de estilo arcade.
- [terraform/](file:///home/tomas-drago/Pin%20final/terraform) — Código de aprovisionamiento de AWS.
  - [alb.tf](file:///home/tomas-drago/Pin%20final/terraform/alb.tf) — Load Balancer y enrutamiento.
  - [ec2.tf](file:///home/tomas-drago/Pin%20final/terraform/ec2.tf) — Instancia EC2 en subred privada con script de arranque.
  - [ecr.tf](file:///home/tomas-drago/Pin%20final/terraform/ecr.tf) — Registro privado de imágenes Docker (ECR).
  - [iam.tf](file:///home/tomas-drago/Pin%20final/terraform/iam.tf) — Roles de IAM y perfiles de instancia seguros.
  - [outputs.tf](file:///home/tomas-drago/Pin%20final/terraform/outputs.tf) — Variables de salida de Terraform.
  - [providers.tf](file:///home/tomas-drago/Pin%20final/terraform/providers.tf) — Configuración de proveedores (AWS).
  - [security_groups.tf](file:///home/tomas-drago/Pin%20final/terraform/security_groups.tf) — Firewalls virtuales (ALB y EC2).
  - [terraform.tfvars](file:///home/tomas-drago/Pin%20final/terraform/terraform.tfvars) — Valores configurados para las variables.
  - [variables.tf](file:///home/tomas-drago/Pin%20final/terraform/variables.tf) — Variables de entrada parametrizadas.
  - [vpc.tf](file:///home/tomas-drago/Pin%20final/terraform/vpc.tf) — Infraestructura de Red (VPC, Subredes, Ruteo, Gateways).
- [README.md](file:///home/tomas-drago/Pin%20final/README.md) — Documentación general y guía paso a paso.

---

## 🛠️ 1. Infraestructura con Terraform (AWS)

Se despliega una arquitectura de red y cómputo segura basada en los siguientes recursos definidos en los archivos `.tf`:

* **Red (VPC) - [vpc.tf](file:///home/tomas-drago/Pin%20final/terraform/vpc.tf):**
  * `aws_vpc`: VPC principal con bloque CIDR parametrizado (ej. `10.0.0.0/16`).
  * `aws_subnet` (Públicas): 2 subredes públicas en diferentes zonas de disponibilidad para alta disponibilidad del ALB.
  * `aws_subnet` (Privada): 1 subred privada donde corre la instancia de cómputo (EC2), aislada del exterior.
  * `aws_internet_gateway` (IGW): Habilita comunicación de red para las subredes públicas.
  * `aws_eip` y `aws_nat_gateway`: Puerta de enlace NAT para permitir que la máquina EC2 en la subred privada descargue paquetes/imágenes desde internet, sin recibir conexiones entrantes no deseadas.
  * `aws_route_table` y `aws_route_table_association`: Enrutamiento público hacia el IGW y privado hacia el NAT Gateway.
* **Cómputo - [ec2.tf](file:///home/tomas-drago/Pin%20final/terraform/ec2.tf):**
  * `aws_instance`: Instancia EC2 basada en Amazon Linux 2023 (`t2.micro` por defecto).
    * **User Data:** Script de inicialización que:
      1. Actualiza el sistema e instala Docker.
      2. Inicia el servicio de Docker.
      3. Agrega al usuario `ec2-user` al grupo Docker.
      4. Se autentica en ECR.
      5. Descarga (`docker pull`) la última versión de la imagen de Mario RPG.
      6. Ejecuta el contenedor expuesto en el puerto `80`.
    * **IMDSv2:** Activado obligatoriamente (`http_tokens = "required"`) para mayor seguridad de metadatos.
  * `aws_lb_target_group_attachment`: Asocia la instancia EC2 al Target Group del ALB.
* **Balanceador de Carga - [alb.tf](file:///home/tomas-drago/Pin%20final/terraform/alb.tf):**
  * `aws_lb`: Application Load Balancer público asociado a las subredes públicas.
  * `aws_lb_target_group`: Target Group escuchando en puerto 80 HTTP con un Health Check configurado sobre `/`.
  * `aws_lb_listener`: Listener HTTP en puerto 80 que redirige el tráfico al Target Group.
* **Registro de Contenedores - [ecr.tf](file:///home/tomas-drago/Pin%20final/terraform/ecr.tf):**
  * `aws_ecr_repository`: Registro privado con mutabilidad de tags habilitada y escaneo de imágenes al subir (`scan_on_push = true`).
* **Seguridad (Security Groups) - [security_groups.tf](file:///home/tomas-drago/Pin%20final/terraform/security_groups.tf):**
  * ALB SG: Permite tráfico entrante HTTP (`TCP/80`) desde cualquier origen e internet.
  * EC2 SG: Permite tráfico entrante HTTP (`TCP/80`) **únicamente** originado por el Security Group del ALB. Bloquea todo acceso directo desde internet.
* **Accesos (IAM) - [iam.tf](file:///home/tomas-drago/Pin%20final/terraform/iam.tf):**
  * `aws_iam_role`: Rol asignado a la EC2.
  * Políticas adjuntas:
    * `AmazonEC2ContainerRegistryReadOnly`: Permite a la EC2 descargar imágenes de ECR sin usar claves estáticas.
    * `AmazonSSMManagedInstanceCore`: Permite administrar y conectarse a la EC2 en la subred privada de forma segura usando AWS Systems Manager (SSM) Session Manager, eliminando la necesidad de abrir puertos de SSH (`TCP/22`).
  * `aws_iam_instance_profile`: Perfil de instancia IAM asignado a la EC2.

---

## 🎮 2. Aplicación y Dockerfile

La aplicación es un juego interactivo de Mario RPG desarrollado con tecnologías web estándar (HTML5 Canvas, CSS y JavaScript) ubicado en el directorio `mario-rpg/`.

El estado del archivo **[Dockerfile](file:///home/tomas-drago/Pin%20final/mario-rpg/Dockerfile)** es el siguiente:
* Utiliza una imagen base ultra ligera de Nginx sobre Alpine Linux (`FROM nginx:alpine`).
* Copia localmente los tres archivos principales (`index.html`, `style.css` y `script.js`) al directorio de contenido estático por defecto de Nginx (`/usr/share/nginx/html/`).
* Expone el puerto `80` (`EXPOSE 80`).
* Nginx arranca por defecto con la imagen base, por lo que no requiere una instrucción `CMD` personalizada.

---

## 🚀 3. Estado del Pipeline (CI/CD)

Existe una pipeline de integración y despliegue continuo configurada en **[.github/workflows/cicd.yml](file:///home/tomas-drago/Pin%20final/.github/workflows/cicd.yml)** con dos trabajos principales:

1. **Trabajo `security-and-quality` (Análisis de Seguridad y Calidad):**
   * Se ejecuta en cualquier `push` o `pull_request` hacia las ramas `main` o `master`.
   * **Pasos (Steps):**
     1. **Checkout Code:** Descarga del repositorio usando `actions/checkout@v4` con `fetch-depth: 0` (necesario para históricos completos).
     2. **Gitleaks Scan:** Análisis estático con `gitleaks/gitleaks-action@v2` para detectar posibles secretos (API keys, contraseñas) expuestos en el historial.
     3. **SonarQube Scan:** Análisis de calidad de código con `sonarsource/sonarqube-scan-action@v2` (configurado con `continue-on-error: true` para evitar bloqueos si no está configurada la instancia de SonarQube).
2. **Trabajo `build-and-push` (Compilación y Subida a ECR):**
   * Se ejecuta en `ubuntu-latest` y **solo en eventos de `push`** a ramas principales, una vez que `security-and-quality` finaliza con éxito.
   * **Pasos (Steps):**
     1. **Checkout Code.**
     2. **Configure AWS Credentials:** Configura las credenciales usando `aws-actions/configure-aws-credentials@v4` a través de los secretos `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` y `AWS_REGION`.
     3. **Login to Amazon ECR:** Autenticación automática de Docker en el registro con `aws-actions/amazon-ecr-login@v2`.
     4. **Build, Tag, and Push Image to ECR:** Cambia al directorio `mario-rpg/`, compila la imagen etiquetándola con el commit SHA (`github.sha`) y con `latest`, y finalmente las sube al ECR.

---

## 🔒 4. Seguridad y Observabilidad

A continuación se detalla la cobertura actual de las herramientas solicitadas frente a lo implementado:

| Herramienta Requerida | Estado actual | Detalle en el Código / Repositorio |
| :--- | :--- | :--- |
| **Gitleaks** | **Integrado** | Configurado en el step `Gitleaks Scan` dentro de [.github/workflows/cicd.yml](file:///home/tomas-drago/Pin%20final/.github/workflows/cicd.yml). |
| **SonarQube** | **Integrado (Básico)** | Configurado en [.github/workflows/cicd.yml](file:///home/tomas-drago/Pin%20final/.github/workflows/cicd.yml) usando el plugin oficial. Funciona condicionado a secretos (`SONAR_TOKEN`, `SONAR_HOST_URL`). |
| **ESLint** | **No Integrado** | No hay archivos de configuración ni pasos en la pipeline para ESLint en el código actual. |
| **Snyk** | **No Integrado** | No se encuentra integrada la herramienta Snyk en la pipeline ni en el repositorio. |
| **SBOM (CycloneDX/SPDX)** | **No Integrado** | No se generan manifiestos de software (SBOM) actualmente. |
| **ECR Image Scan** | **Integrado** | Terraform habilita el escaneo automático al hacer push (`scan_on_push = true`) en [ecr.tf](file:///home/tomas-drago/Pin%20final/terraform/ecr.tf). |
| **Prometheus** | **No Integrado** | No existen agentes, exporters ni archivos de configuración para Prometheus. |
| **Grafana** | **No Integrado** | No hay dashboards ni configuraciones integradas para Grafana. |

---

## 📝 5. Código Fuente Clave

A continuación se incluye el código de los archivos principales del proyecto.

### 📄 Dockerfile
Ubicación: [mario-rpg/Dockerfile](file:///home/tomas-drago/Pin%20final/mario-rpg/Dockerfile)
```dockerfile
# Usamos una imagen ligera de Nginx basada en Alpine Linux
FROM nginx:alpine

# Copiamos los archivos de nuestra aplicación web al directorio por defecto de Nginx
COPY index.html /usr/share/nginx/html/index.html
COPY style.css /usr/share/nginx/html/style.css
COPY script.js /usr/share/nginx/html/script.js

# Exponemos el puerto 80 del contenedor
EXPOSE 80

# Nginx inicia automáticamente en el comando por defecto de la imagen base,
# por lo que no es estrictamente necesario añadir un CMD personalizado.
```

### 📄 .github/workflows/cicd.yml
Ubicación: [.github/workflows/cicd.yml](file:///home/tomas-drago/Pin%20final/.github/workflows/cicd.yml)
```yaml
name: CI/CD Pipeline - Super Mario RPG

on:
  push:
    branches: [ "main", "master" ]
  pull_request:
    branches: [ "main", "master" ]

jobs:
  security-and-quality:
    name: Análisis de Seguridad y Calidad
    runs-on: ubuntu-latest
    steps:
      # Step 1: Descargar el código
      - name: Checkout Code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0 # Necesario para que Gitleaks y SonarQube analicen todo el historial

      # Step 2: Escaneo de secretos con Gitleaks
      - name: Gitleaks Scan (Secret Detection)
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        # continue-on-error: true # Opcional: descomenta si no quieres bloquear el pipeline por advertencias en fase inicial

      # Step 3: Análisis estático de código con SonarQube
      - name: SonarQube Scan
        uses: sonarsource/sonarqube-scan-action@v2
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
          SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
        continue-on-error: true

  build-and-push:
    name: Build & Push to Amazon ECR
    needs: security-and-quality
    runs-on: ubuntu-latest
    if: github.event_name == 'push' # Solo pushea a ECR cuando se hace merge/push en ramas principales
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      # Step 1: Configurar credenciales de AWS
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION || 'us-east-1' }}

      # Step 2: Autenticación en Amazon ECR
      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      # Step 3: Construcción y subida de la imagen Docker
      - name: Build, Tag, and Push Image to ECR
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          ECR_REPOSITORY: ${{ secrets.ECR_REPOSITORY || 'mario-rpg-repo' }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          # Cambiamos al directorio de la aplicación
          cd mario-rpg
          
          # Compilar imagen localmente
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG -t $ECR_REGISTRY/$ECR_REPOSITORY:latest .
          
          # Subir la etiqueta específica del Commit SHA y la etiqueta 'latest'
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
```

### 📄 terraform/vpc.tf
Ubicación: [terraform/vpc.tf](file:///home/tomas-drago/Pin%20final/terraform/vpc.tf)
```hcl
# 1. Obtener zonas de disponibilidad dinámicamente de la región seleccionada
data "aws_availability_zones" "available" {
  state = "available"
}

# 2. Creación de la VPC principal
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# 3. Internet Gateway para permitir salida/entrada a internet desde subredes públicas
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# 4. Subredes Públicas (requeridas por el ALB)
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true # Otorga IP pública a los recursos aquí

  tags = {
    Name = "${var.project_name}-subnet-public-${count.index + 1}"
  }
}

# 5. Subred Privada (donde se ubica la EC2)
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_name}-subnet-private"
  }
}

# 6. Elastic IP para el NAT Gateway
resource "aws_eip" "nat_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

# 7. NAT Gateway para permitir que la EC2 privada acceda a internet (descargar Docker, imágenes, etc.)
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public[0].id # Ubicado en la primera subred pública

  tags = {
    Name = "${var.project_name}-nat-gateway"
  }

  depends_on = [aws_internet_gateway.igw]
}

# 8. Tabla de Ruteo Pública (Apunta al Internet Gateway)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-rt-public"
  }
}

# 9. Tabla de Ruteo Privada (Apunta al NAT Gateway)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.project_name}-rt-private"
  }
}

# 10. Asociación de Tablas de Ruteo a las Subredes Públicas
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# 11. Asociación de Tabla de Ruteo a la Subred Privada
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
```

### 📄 terraform/ec2.tf
Ubicación: [terraform/ec2.tf](file:///home/tomas-drago/Pin%20final/terraform/ec2.tf)
```hcl
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
              aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.mario_repo.repository_url}

              # 5. Descargar la imagen del repositorio
              docker pull ${aws_ecr_repository.mario_repo.repository_url}:latest

              # 6. Ejecutar el contenedor escuchando en el puerto 80
              docker run -d --name mario-rpg -p 80:80 --restart always ${aws_ecr_repository.mario_repo.repository_url}:latest
              EOF

  # metadata_options para forzar el uso de IMDSv2
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
```

### 📄 terraform/alb.tf
Ubicación: [terraform/alb.tf](file:///home/tomas-drago/Pin%20final/terraform/alb.tf)
```hcl
# 1. Application Load Balancer Público
resource "aws_lb" "mario_alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# 2. Grupo de Destino (Target Group) para la EC2
resource "aws_lb_target_group" "mario_tg" {
  name        = "${var.project_name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  # Configuración del Health Check
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

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mario_tg.arn
  }
}
```

### 📄 terraform/ecr.tf
Ubicación: [terraform/ecr.tf](file:///home/tomas-drago/Pin%20final/terraform/ecr.tf)
```hcl
# Registro ECR para almacenar la imagen Docker de Mario RPG
resource "aws_ecr_repository" "mario_repo" {
  name                 = "${var.project_name}-repo"
  image_tag_mutability = "MUTABLE"

  # Escaneo automático de vulnerabilidades al subir la imagen
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-repo"
  }
}
```

### 📄 terraform/security_groups.tf
Ubicación: [terraform/security_groups.tf](file:///home/tomas-drago/Pin%20final/terraform/security_groups.tf)
```hcl
# 1. Grupo de Seguridad para el Application Load Balancer (Público)
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Permite acceso HTTP publico al balanceador"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "HTTP desde el exterior"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

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
  description = "Permite trafico entrante únicamente desde el ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP desde el ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

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
```

### 📄 terraform/iam.tf
Ubicación: [terraform/iam.tf](file:///home/tomas-drago/Pin%20final/terraform/iam.tf)
```hcl
# 1. Definición del Rol IAM para la instancia EC2
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-role"
  }
}

# 2. Adjuntar política para lectura de ECR (AmazonEC2ContainerRegistryReadOnly)
resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# 3. Adjuntar política para acceso por AWS SSM Session Manager (AmazonSSMManagedInstanceCore)
resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 4. Crear el Perfil de Instancia de IAM para asignárselo a la EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
```
