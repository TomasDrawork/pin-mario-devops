# Usamos una imagen ligera de Nginx basada en Alpine Linux
FROM nginx:alpine

# Copiamos la configuración personalizada de Nginx
COPY default.conf /etc/nginx/conf.d/default.conf

# Copiamos los archivos de nuestra aplicación web al directorio por defecto de Nginx
COPY index.html /usr/share/nginx/html/index.html
COPY style.css /usr/share/nginx/html/style.css
COPY script.js /usr/share/nginx/html/script.js

# Exponemos el puerto 80 del contenedor
EXPOSE 80