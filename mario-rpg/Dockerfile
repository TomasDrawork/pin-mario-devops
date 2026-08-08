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
