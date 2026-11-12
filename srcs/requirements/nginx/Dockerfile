FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y --no-install-recommends nginx openssl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl /run/nginx /var/www/wordpress && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -out /etc/nginx/ssl/inception.crt \
      -keyout /etc/nginx/ssl/inception.key \
      -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=42/CN=msingh.42.fr/UID=msingh"

COPY conf/nginx.conf /etc/nginx/nginx.conf

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
