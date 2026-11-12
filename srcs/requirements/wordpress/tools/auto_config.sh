#!/bin/bash
set -e

mkdir -p /run/php /var/www/wordpress
cd /var/www/wordpress

echo "Attente de MariaDB..."
until mariadb -h mariadb -u"${SQL_USER}" -p"${SQL_PASSWORD}" \
    -e "USE \`${SQL_DATABASE}\`; SELECT 1;" >/dev/null 2>&1; do
    sleep 2
done

if [ ! -f wp-load.php ]; then
    echo "Téléchargement de WordPress..."
    wp core download --allow-root --path=/var/www/wordpress
fi

if [ ! -f wp-config.php ]; then
    echo "Création de wp-config.php..."
    wp config create \
        --allow-root \
        --path=/var/www/wordpress \
        --dbname="${SQL_DATABASE}" \
        --dbuser="${SQL_USER}" \
        --dbpass="${SQL_PASSWORD}" \
        --dbhost="mariadb:3306" \
        --dbcharset="utf8mb4"
fi

if ! wp core is-installed --allow-root --path=/var/www/wordpress; then
    echo "Installation de WordPress..."
    wp core install \
        --allow-root \
        --path=/var/www/wordpress \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email
fi

if ! wp user get "${WP_USER}" --allow-root --path=/var/www/wordpress >/dev/null 2>&1; then
    if ! wp user get "${WP_USER_EMAIL}" --field=ID --allow-root --path=/var/www/wordpress >/dev/null 2>&1; then
        wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
            --allow-root \
            --path=/var/www/wordpress \
            --user_pass="${WP_USER_PASSWORD}" \
            --role=author
    fi
fi

wp config set WP_REDIS_HOST redis --allow-root --path=/var/www/wordpress
wp config set WP_REDIS_PORT 6379 --raw --allow-root --path=/var/www/wordpress
wp config set WP_CACHE_KEY_SALT "${DOMAIN_NAME}:" --allow-root --path=/var/www/wordpress

if ! wp plugin is-installed redis-cache --allow-root --path=/var/www/wordpress; then
    wp plugin install redis-cache --activate --allow-root --path=/var/www/wordpress
elif ! wp plugin is-active redis-cache --allow-root --path=/var/www/wordpress; then
    wp plugin activate redis-cache --allow-root --path=/var/www/wordpress
fi
wp redis enable --allow-root --path=/var/www/wordpress || true

chown -R www-data:www-data /var/www/wordpress

echo "Démarrage de PHP-FPM..."
exec php-fpm8.2 -F
