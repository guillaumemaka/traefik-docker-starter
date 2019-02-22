FROM traefik:1.7.9-alpine
LABEL authors="Guillaume Maka <guillaume.maka@gmail.com>"
COPY ./traefik /etc/traefik
COPY entrypoint.sh /