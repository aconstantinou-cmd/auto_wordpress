#!/bin/bash

# check if docker is installed
if ! command -v docker &> /dev/null
then
    echo "Docker is not installed. Please install it and re-run the script."
    exit
fi

# check if docker-compose is installed
if ! command -v docker-compose &> /dev/null
then
    echo "Docker-compose is not installed. Please install it and re-run the script."
    exit
fi

read -p "Please enter your email: " email
read -p "Please enter your domain: " domain


cat << EOF > docker-compose.yml
version: '3'
services:
  nginx-proxy:
    image: jwilder/nginx-proxy:alpine
    labels:
      - "com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy=true"
    container_name: ${domain}_nginx-proxy
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro
      - certs:/etc/nginx/certs
      - vhostd:/etc/nginx/vhost.d
      - html:/usr/share/nginx/html

  letsencrypt-nginx-proxy-companion:
    image: jrcs/letsencrypt-nginx-proxy-companion
    container_name: ${domain}_letsencrypt-nginx-proxy-companion
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - certs:/etc/nginx/certs
      - vhostd:/etc/nginx/vhost.d
      - html:/usr/share/nginx/html
    depends_on:
      - nginx-proxy

  wordpress:
    depends_on:
      - db
    image: wordpress:latest
    container_name: ${domain}_wordpress
    expose:
      - 80
    environment:
      - WORDPRESS_DB_HOST=db
      - WORDPRESS_DB_USER=wordpress
      - WORDPRESS_DB_PASSWORD=secure_password
      - WORDPRESS_DB_NAME=wordpress
      - VIRTUAL_HOST=${domain}
      - LETSENCRYPT_HOST=${domain}
      - LETSENCRYPT_EMAIL=${email}

  db:
    image: mysql:5.7
    container_name: ${domain}_db
    environment:
      - MYSQL_DATABASE=wordpress
      - MYSQL_USER=wordpress
      - MYSQL_PASSWORD=secure_password
      - MYSQL_RANDOM_ROOT_PASSWORD='1'

volumes:
  certs:
  vhostd:
  html:
EOF

docker-compose up -d
