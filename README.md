# Super Mario RPG - DevOps & Infrastructure as Code (IaC) 🍄🚀

![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=Prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/grafana-%23F46800.svg?style=for-the-badge&logo=grafana&logoColor=white)
![Nginx](https://img.shields.io/badge/nginx-%23009639.svg?style=for-the-badge&logo=nginx&logoColor=white)

Este repositorio contiene la solución completa de ingeniería DevOps e Infraestructura como Código (IaC) desarrollada para el **Proyecto Integrador Final (PIN)**.

Aprovisiona una arquitectura multi-servicio segura, escalable y tolerante a fallos en **AWS con Terraform**, desplegando automáticamente una aplicación web junto con su stack completo de observabilidad (**Prometheus + Grafana**) a través de un pipeline automatizado de **CI/CD en GitHub Actions**.

---

## 📸 Demostración Visual y Evidencias

### ☁️ Despliegue en Producción (AWS)
| Juego en AWS (Vía ALB) | Dashboard de Grafana en Vivo (Vía SSM Tunnel) |
| :---: | :---: |
| ![Juego en AWS](entregables/aws/pruebasderequests.png) | ![Grafana AWS](entregables/aws/dashboardAWS2.png) |

### 💻 Entorno de Desarrollo Local (Docker Compose)
| Juego Local (`localhost:8081`) | Monitoreo Local (`localhost:3000`) |
| :---: | :---: |
| ![Juego Local](entregables/local/appmario.png) | ![Grafana Local](entregables/local/dashboard-grafana-local2.png) |

---

## 📁 Estructura del Repositorio
* **`mario-rpg/`**: Aplicación web (HTML5/Canvas) empaquetada en un servidor Nginx ligero optimizado para exponer métricas (`/stub_status`).
* **`monitoring/`**: Configuraciones de aprovisionamiento de Prometheus (`prometheus.yml`) y Grafana (`datasource.yml`).
* **`.github/workflows/cicd.yml`**: Pipeline automatizado de CI/CD (Gitleaks, ESLint, Snyk, SonarQube, generación de SBOM y Build & Push a ECR).
* **`terraform/`**: Código de Infraestructura como Código (VPC, Subredes Públicas/Privadas, ALB, EC2, NAT Gateway, ECR, IAM, Security Groups).
* **`entregables/`**: Artefactos de auditoría de seguridad (SBOM CycloneDX JSON) y capturas de pantalla de prueba en local y nube.

---

## 🛠️ Arquitectura de Red y Seguridad (AWS)
* **VPC Privada & Aislada:** La instancia EC2 reside en una subred privada sin IP pública directa, previniendo ataques y escaneos externos.
* **Application Load Balancer (ALB):** Ubicado en subredes públicas; actúa como el único punto de entrada autorizado para el tráfico web (Puerto 80).
* **Security Groups Estrictos:** La EC2 solo permite tráfico entrante en el puerto 80 originado desde el Security Group del ALB.
* **Cero Puertos SSH Abiertos (Zero-Trust):** La administración y depuración remota se realizan mediante **AWS Systems Manager (SSM) Session Manager**, eliminando el puerto 22 y el uso de llaves estáticas (`.pem`).
* **Roles de IAM & IMDSv2:** Autenticación a Amazon ECR mediante IAM Instance Profile e inspección segura de metadatos con IMDSv2.

---

## 🤖 Pipeline de CI/CD (GitHub Actions)

El workflow automatizado se divide en dos jobs principales:
1. **Quality & Security Gate:**
   * **Gitleaks:** Detección de secretos o claves expuestas.
   * **ESLint:** Análisis de calidad de código JavaScript.
   * **Snyk:** Escaneo de vulnerabilidades en dependencias.
   * **SonarQube:** Análisis estático de código.
   * **SBOM (CycloneDX):** Generación automática del inventario de software `sbom.json` en formato estándar CycloneDX.
2. **Build & Deploy:**
   * Autenticación segura en AWS ECR.
   * Compilación de la imagen de producción con etiquetado dinámico (Commit SHA + `latest`).
   * Publicación al registro de imágenes privadas de AWS.

---

## 💻 Ejecución Local (Desarrollo)

Para levantar el entorno completo de desarrollo local con los 4 contenedores (`mario-app`, `nginx-exporter`, `prometheus`, `grafana`):

```bash
docker compose up -d --build
```

### Accesos Locales:
* **Juego:** [http://localhost:8081](http://localhost:8081)
* **Prometheus:** [http://localhost:9090](http://localhost:9090)
* **Grafana:** [http://localhost:3000](http://localhost:3000) *(Usuario: `admin` / Contraseña: `admin`)*.

---

## 🚀 Despliegue en la Nube (AWS)

### 1. Aprovisionar Infraestructura
```bash
cd terraform
terraform init
terraform apply -auto-approve
```

### 2. Actualización de la EC2 (Cloud-Init)
Tras ejecutar la pipeline en GitHub Actions, reemplaza la máquina para descargar la versión más reciente del ECR:
```bash
terraform apply -replace="aws_instance.mario_app" -auto-approve
```

### 3. Acceso Seguro a Grafana (Túnel SSM)
```bash
aws ssm start-session \
  --region us-east-1 \
  --target <EC2_INSTANCE_ID> \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["3000"],"localPortNumber":["3000"]}'
```
Accede a Grafana en [http://localhost:3000](http://localhost:3000) para ver el dashboard de monitoreo en tiempo real.

---

## 🧹 Limpieza de Recursos (AWS)

```bash
# Eliminar el repositorio ECR
aws ecr delete-repository --repository-name mario-rpg-repo --force --region us-east-1

# Destruir la infraestructura en AWS
cd terraform
terraform destroy -auto-approve
```

---

*Proyecto desarrollado por **Tomás Drago (Grupo 15)** para la Diplomatura en DevOps.*
