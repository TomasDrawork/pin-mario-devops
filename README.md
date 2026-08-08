# Super Mario RPG - DevOps & Terraform Edition 🍄🚀

Este repositorio contiene un proyecto diseñado para aprender el uso práctico de **Terraform (Infraestructura como Código)** junto con una pipeline de **CI/CD en GitHub Actions**, integrando prácticas de calidad de código y seguridad antes de desplegar en **AWS**.

---

## 📁 Estructura del Proyecto

El repositorio está organizado de la siguiente manera:

```
├── README.md                          # Esta guía de uso y aprendizaje
├── mario-rpg/                         # Código de la aplicación web (HTML5/Canvas)
│   ├── index.html                     # Tablero del juego Mario RPG
│   ├── style.css                      # Estilos retro de estilo arcade
│   ├── script.js                      # Mecánicas, física y sonido del juego
│   └── Dockerfile                     # Empaquetado del servidor web con Nginx
├── .github/
│   └── workflows/
│       └── cicd.yml                   # Pipeline de GitHub Actions (Quality/Security/Deploy)
└── terraform/                         # Código de aprovisionamiento de AWS
    ├── providers.tf                   # Configuración del proveedor de AWS
    ├── variables.tf                   # Variables de entrada parametrizadas
    ├── terraform.tfvars               # Valores configurados para las variables
    ├── vpc.tf                         # Infraestructura de Red (VPC, Subredes, Gateways)
    ├── iam.tf                         # Roles de IAM y perfiles de instancia seguros
    ├── security_groups.tf             # Firewalls virtuales (ALB y EC2)
    ├── ecr.tf                         # Registro privado de imágenes Docker (ECR)
    ├── alb.tf                         # Application Load Balancer y enrutamiento
    ├── ec2.tf                         # Instancia EC2 en subred privada con script de arranque
    └── outputs.tf                     # Salida de datos (DNS del Load Balancer, URL de ECR)
```

---

## 🧠 ¿Cómo funciona Terraform?

Terraform es una herramienta **declarativa**. Esto significa que tú defines el **estado deseado** de tu infraestructura (por ejemplo, "quiero una VPC y una máquina virtual") y Terraform se encarga de determinar los pasos necesarios para crearla, modificarla o eliminarla.

### Ciclo de vida y comandos fundamentales:

1. **`terraform init`**
   - **Qué hace:** Prepara el directorio de trabajo. Descarga el plugin del proveedor de AWS especificado en `providers.tf` y los módulos necesarios.
   - **Cuándo usarlo:** La primera vez que trabajas con el proyecto o cuando agregas un nuevo proveedor.

2. **`terraform plan`**
   - **Qué hace:** Compara tu código local contra el estado actual en la nube de AWS y genera un plan de acción (crear, modificar o destruir recursos).
   - **Cuándo usarlo:** Siempre antes de realizar un cambio para asegurarte de que no habrá efectos secundarios no deseados.

3. **`terraform apply`**
   - **Qué hace:** Ejecuta las acciones propuestas en el plan. Realiza las llamadas API de AWS necesarias para crear la infraestructura real. Genera o actualiza el archivo `terraform.tfstate`.
   - **Cuándo usarlo:** Cuando quieres desplegar o aplicar tus cambios en la nube.

4. **`terraform destroy`**
   - **Qué hace:** Elimina todos los recursos que fueron creados por este código de Terraform.
   - **Cuándo usarlo:** Cuando ya no necesitas la infraestructura y quieres evitar costos (muy importante para este ejercicio).

### El archivo de Estado (`terraform.tfstate`)
Terraform guarda un registro del estado real de la infraestructura en un archivo local llamado `terraform.tfstate`. **Nunca edites este archivo manualmente**. Es el que permite a Terraform saber qué recursos ya existen para no duplicarlos en la próxima ejecución.

---

## 🛠️ Arquitectura de Red y Seguridad Desplegada

Para proteger tu aplicación siguiendo las mejores prácticas de AWS, hemos diseñado la siguiente topología de red:

* **VPC Privada y Aislada:** Ningún recurso está expuesto directamente a internet sin control.
* **Subredes Públicas:** Albergan el **Application Load Balancer (ALB)**. Su función es recibir tráfico en el puerto 80 y distribuirlo hacia la red privada.
* **Subred Privada:** Aquí reside la **instancia EC2**. Al estar en una subred privada, no tiene IP pública directa. Nadie en internet puede hacerle un "ping" o intentar hackearla directamente.
* **NAT Gateway:** Se sitúa en la subred pública. Permite que la EC2 privada tenga salida a internet para descargar paquetes e imágenes de ECR, pero no permite que se inicien conexiones desde el exterior hacia ella.
* **Mínimo Privilegio de IAM:** La EC2 asume un rol de IAM específico (`AmazonEC2ContainerRegistryReadOnly`) que solo le da permiso para descargar imágenes desde ECR, evitando credenciales estáticas en código.
* **Seguridad a Nivel de Red (Security Groups):** El grupo de seguridad de la EC2 solo permite tráfico entrante desde el grupo de seguridad del ALB. Esto garantiza que todo el tráfico pase obligatoriamente por el balanceador.

---

## 🚀 Guía Paso a Paso para Desplegar el Proyecto

### Requisitos Previos:
- Una cuenta de **AWS** activa.
- Un repositorio en **GitHub** con este código.
- Tener instalado **Terraform** y **AWS CLI** localmente (si decides desplegar desde tu máquina).

### Paso 1: Configurar el Repositorio de GitHub y AWS
Para que la pipeline de GitHub Actions pueda conectarse a tu AWS y subir la imagen Docker, debes añadir los siguientes secretos en tu repositorio (ve a **Settings > Secrets and variables > Actions > New repository secret**):
- `AWS_ACCESS_KEY_ID`: Tu ID de clave de acceso de AWS.
- `AWS_SECRET_ACCESS_KEY`: Tu clave de acceso secreta de AWS.
- `AWS_REGION`: Ej. `us-east-1`.

*(Opcional para SonarQube)*:
- `SONAR_TOKEN` y `SONAR_HOST_URL` (puedes omitirlos o dejarlos vacíos, la pipeline continuará con advertencia).

### Paso 2: Inicializar y Desplegar ECR con Terraform
1. Abre una terminal en la carpeta `terraform/` de este proyecto.
2. Inicia Terraform:
   ```bash
   terraform init
   ```
3. Verifica qué se creará:
   ```bash
   terraform plan
   ```
4. Aplica los cambios para levantar la infraestructura:
   ```bash
   terraform apply -auto-approve
   ```
5. Toma nota del output llamado `ecr_repository_url` y `alb_dns_name`.

### Paso 3: Ejecutar la Pipeline de CI/CD (GitHub Actions)
1. Si creaste el repositorio en GitHub, haz un `git push` de tu código a la rama principal (`main` o `master`).
2. La pipeline se iniciará automáticamente. Realizará las fases de:
   - **Gitleaks:** Escaneo de secretos.
   - **SonarQube:** Análisis de calidad.
   - **Build & Push:** Compilará la imagen de Docker usando el `Dockerfile` de `mario-rpg/` y la subirá a tu repositorio ECR en AWS.
3. Espera a que la pipeline termine con éxito.

### Paso 4: Actualización Automática de la EC2
Gracias al script `user_data` que configuramos en la EC2 (`ec2.tf`), la instancia en su arranque inicial:
1. Instalará Docker.
2. Se autenticará automáticamente en AWS ECR usando su Rol de IAM asignado.
3. Descargará la imagen de Mario RPG que la pipeline acaba de subir (`latest`).
4. Levantará el contenedor en el puerto 80.

*Nota:* Si necesitas redesplegar un cambio en el código del juego, puedes reiniciar la instancia EC2 para que el script `user_data` vuelva a ejecutarse y descargue la última imagen compilada de ECR, o bien configurar soluciones avanzadas de despliegue como AWS CodeDeploy o ECS.

### Paso 5: ¡A Jugar!
1. Copia el valor de `alb_dns_name` devuelto por Terraform (o búscalo en la consola de AWS en la sección de EC2 > Load Balancers).
2. Pégalo en tu navegador web: `http://<TU-ALB-DNS-NAME>`.
3. Verás la pantalla del Super Mario RPG corriendo en AWS. ¡Disfruta el juego esquivando las bolas de fuego de Bowser!

---

## 🧹 Limpieza (Evitar Costos)
Una vez que hayas terminado de aprender y probar el proyecto, asegúrate de destruir los recursos en AWS para que no se te cobren cargos por el NAT Gateway o la EC2:
```bash
# Dentro de la carpeta terraform/
terraform destroy -auto-approve
```
