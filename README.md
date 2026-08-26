# Super Mario RPG - PIN DevOps & IaC 🍄🚀

Este repositorio contiene la solución para el **Proyecto 1: CI/CD con GitHub Actions + Terraform + Docker** correspondiente al Proyecto Integrador Final (PIN).

Aprovisiona una arquitectura segura y escalable en AWS con Terraform y despliega automáticamente la aplicación junto con su stack de observabilidad (Prometheus + Grafana) a través de un pipeline automatizado.

---

## 📁 Estructura del Proyecto
* **`mario-rpg/`**: Código de la aplicación web (HTML5/Canvas) y empaquetado con Nginx.
* **`monitoring/`**: Configuraciones de aprovisionamiento automático para Prometheus y Grafana.
* **`.github/workflows/cicd.yml`**: Pipeline automatizado de calidad de código, escaneos de seguridad, generación de SBOM y despliegue.
* **`terraform/`**: Manifiestos de Terraform para levantar toda la infraestructura de red, seguridad, ECR, ALB y cómputo en AWS.

---

## 🛠️ Arquitectura y Seguridad
* **Red Privada (VPC Aislada):** La instancia EC2 reside en una subred privada sin dirección IP pública directa para evitar accesos indebidos.
* **Balanceador de Carga (ALB):** Se ubica en subredes públicas y es el único punto de entrada autorizado desde internet para el tráfico web (puerto 80).
* **Mínimo Privilegio (Security Groups):** La EC2 solo acepta tráfico HTTP originado desde el propio balanceador de carga.
* **Roles IAM Activos:** Acceso seguro a ECR mediante IAM Instance Profile (evitando claves de acceso fijas) y conectividad mediante AWS Systems Manager (SSM) sin abrir puertos SSH (22).

---

## 💻 Ejecución Local (Desarrollo y Pruebas)
Para validar la aplicación y el monitoreo en tu computadora local antes de ir a AWS, ejecuta desde la raíz:

```bash
docker compose up -d --build
```

### Accesos Locales:
* **Juego (Mario RPG):** [http://localhost:8081](http://localhost:8081)
* **Prometheus:** [http://localhost:9090](http://localhost:9090)
* **Grafana:** [http://localhost:3000](http://localhost:3000) (Usuario: `admin` / Contraseña: `admin`).
  * *Tip:* Para ver los gráficos, ve a **Import**, ingresa el ID **`12708`** (dashboard de Nginx) y selecciona la fuente de datos **Prometheus**.

Para apagar el entorno local: `docker compose down`

---

## 🚀 Despliegue en la Nube (AWS)

### 1. Requisitos Previos
* Cuenta de AWS activa.
* Configurar en los secretos de tu repositorio de GitHub (`Settings > Secrets > Actions`):
  * `AWS_ACCESS_KEY_ID`
  * `AWS_SECRET_ACCESS_KEY`
  * `AWS_REGION` (ej. `us-east-1`)
  * *(Opcional)* `SNYK_TOKEN` para análisis de seguridad.

### 2. Aprovisionar Infraestructura
Desde la carpeta `terraform/` en tu terminal:
```bash
terraform init
terraform plan
terraform apply -auto-approve
```
*Guarda los valores devueltos en la terminal como `ecr_repository_url` y `alb_dns_name`.*

### 3. Pipeline de CI/CD (GitHub Actions)
Haz un `git push` a la rama principal (`main` o `master`). El pipeline se disparará y ejecutará:
1. **Calidad y Seguridad:** Gitleaks (secretos), ESLint (JavaScript) y Snyk (dependencias).
2. **SBOM:** Generará un archivo `sbom.json` en formato CycloneDX que quedará adjunto para descarga en la corrida de GitHub.
3. **Build & Push:** Compilará la imagen de producción y la subirá a tu AWS ECR.

### 4. Acceso en AWS
* **Jugar en la Nube:** Ingresa en tu navegador a `http://<TU-ALB-DNS-NAME>` (devuelto por Terraform).
* **Ver Grafana en AWS (Túnel Seguro):** Grafana corre protegido dentro de la subred privada de AWS. Para entrar de forma segura, ejecuta en tu terminal local:
  ```bash
  aws ssm start-session \
    --target <ID_DE_INSTANCIA_EC2> \
    --document-name AWS-StartPortForwardingSession \
    --parameters '{"portNumber":["3000"],"localPortNumber":["3000"]}'
  ```
  Luego, abre en tu navegador [http://localhost:3000](http://localhost:3000) (Usuario: `admin` / Contraseña: `admin`).

---

## 🧹 Limpieza (Evitar Costos)
Una vez presentadas las capturas del proyecto, destruye toda la infraestructura para no generar gastos en tu cuenta de AWS:
```bash
# Desde la carpeta terraform/
terraform destroy -auto-approve
```
