FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y nginx && \
    rm -rf /var/lib/apt/lists/*

RUN rm -f /etc/nginx/sites-enabled/default

COPY site/ /var/www/static/

RUN chown -R www-data:www-data /var/www/static && \
    chmod -R 755 /var/www/static

RUN printf '%s\n' \
    'server {' \
    '    listen 8080;' \
    '    listen [::]:8080;' \
    '    server_name _;' \
    '    root /var/www/static;' \
    '    index index.html;' \
    '    location / {' \
    '        try_files $uri $uri/ /index.html;' \
    '    }' \
    '}' \
    > /etc/nginx/conf.d/static.conf

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]