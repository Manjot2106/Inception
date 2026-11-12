#!/bin/bash
set -e

mkdir -p /run/mysqld /var/lib/mysql
chown -R mysql:mysql /run/mysqld /var/lib/mysql

if [ ! -d /var/lib/mysql/mysql ]; then
    echo "Initialisation de MariaDB..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql --skip-test-db
fi

echo "Démarrage temporaire de MariaDB..."
mariadbd \
    --user=mysql \
    --datadir=/var/lib/mysql \
    --socket=/run/mysqld/mysqld.sock \
    --skip-networking &
TEMP_PID=$!

until mariadb-admin --socket=/run/mysqld/mysqld.sock ping --silent; do
    sleep 1
done

echo "Configuration de la base et de l'utilisateur..."
mariadb --socket=/run/mysqld/mysqld.sock <<EOF_SQL
CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${SQL_USER}'@'%'
    IDENTIFIED BY '${SQL_PASSWORD}';

ALTER USER '${SQL_USER}'@'%'
    IDENTIFIED BY '${SQL_PASSWORD}';

GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.*
    TO '${SQL_USER}'@'%';

FLUSH PRIVILEGES;
EOF_SQL

mariadb-admin --socket=/run/mysqld/mysqld.sock shutdown
wait "$TEMP_PID"

echo "Démarrage de MariaDB..."
exec mariadbd --user=mysql --datadir=/var/lib/mysql --console
