FROM nginx:latest

COPY build/ /var/www/fexum/public
COPY nginx.conf /etc/nginx/conf.d/default.conf

