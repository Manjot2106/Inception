FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl php-cli php-mysql && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/adminer && \
    curl -fsSL https://www.adminer.org/latest.php -o /var/www/adminer/index.php

WORKDIR /var/www/adminer
EXPOSE 8080
CMD ["php", "-S", "0.0.0.0:8080", "index.php"]
