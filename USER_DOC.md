# Inception – User Documentation

How to start, use and check the Inception stack. Run every `make` command from the repository root.

## 1. Services provided

| Service | Role | Access |
|---|---|---|
| NGINX | HTTPS entry point (TLS 1.2/1.3) | `https://msingh.42.fr` |
| WordPress + PHP-FPM | Website and administration panel | through NGINX |
| MariaDB | Database (posts, users, settings) | internal only |
| Redis *(bonus)* | WordPress object cache | internal only |
| FTP *(bonus)* | File access to the WordPress directory | `msingh.42.fr:21` (passive `40000-40010`) |
| Static website *(bonus)* | Separate portfolio page | `http://msingh.42.fr:8080` |
| Adminer *(bonus)* | Web interface for MariaDB | `http://msingh.42.fr:8081` |
| Dozzle *(bonus)* | Live container logs | `http://msingh.42.fr:8082` |

## 2. Before the first start

1. Map the domain to the machine running Docker:
   ```bash
   echo "127.0.0.1 msingh.42.fr" | sudo tee -a /etc/hosts   # use the VM IP from another computer
   ```
2. Make sure `srcs/.env` exists and contains your own passwords (see section 5), then protect it: `chmod 600 srcs/.env`.

## 3. Start and stop

| Goal | Command |
|---|---|
| Start the core stack (first start builds the images, so it takes longer) | `make` |
| Start core + bonus services | `make bonus` |
| Stop containers (nothing deleted) | `make stop` |
| Start them again | `make start` (core) or `make start_bonus` (core + bonus) |
| Remove containers and network (data kept) | `make down` |
| **Erase everything**: containers, images, volumes and all data | `make fclean` |

> ⚠️ `make fclean` (and `make re`, which calls it) permanently deletes the WordPress content, the database and the data under `/home/msingh/data`.

## 4. Access the website and administration

- **Website:** `https://msingh.42.fr`. The certificate is self-signed, so the browser shows a warning; accept it after checking the host name.
- **WordPress admin panel:** `https://msingh.42.fr/wp-admin`, with the `WP_ADMIN_USER` / `WP_ADMIN_PASSWORD` values from `srcs/.env`. A second, author-level account is defined by `WP_USER` / `WP_USER_PASSWORD`.
- **Adminer:** server `mariadb` (not `localhost`), user/password/database from `SQL_USER`, `SQL_PASSWORD`, `SQL_DATABASE`.
- **FTP:** host `msingh.42.fr`, port `21`, login from `FTP_USER` / `FTP_PASSWORD`; the account is limited to the WordPress files.
- **Dozzle:** open the URL above to read the logs of every container in the browser.

## 5. Locate and manage credentials

All credentials live in **`srcs/.env`** (never committed to Git, never shown in screenshots or recordings):

| Variables | Used for |
|---|---|
| `SQL_DATABASE`, `SQL_USER`, `SQL_PASSWORD`, `SQL_ROOT_PASSWORD` | MariaDB |
| `WP_ADMIN_USER`, `WP_ADMIN_PASSWORD`, `WP_ADMIN_EMAIL` | WordPress administrator |
| `WP_USER`, `WP_USER_PASSWORD`, `WP_USER_EMAIL` | WordPress author |
| `FTP_USER`, `FTP_PASSWORD` | FTP |

The `secrets/` folder contains only empty placeholder files and is not used yet.

**Changing a password:** WordPress account passwords are read from `.env` only at the first installation, so change them in the admin panel (Users → Profile). For any other change to `.env` on an existing installation, use `make re` for a clean state (⚠️ erases all data); a non-destructive procedure for the database password is described in [DEV_DOC.md](DEV_DOC.md).

## 6. Check that everything runs

```bash
make ps                                # core: nginx, wordpress, mariadb must be "Up"
make ps_bonus                          # core + bonus containers
curl -kI https://msingh.42.fr          # any HTTP answer (200/301/302) means NGINX responds
make logs                              # follow logs (Ctrl+C to quit); logs_bonus for all services
```

Further checks (run from `srcs/`):

```bash
docker compose exec wordpress wp core is-installed --allow-root --path=/var/www/wordpress && echo "WordPress OK"
docker compose exec mariadb sh -c 'mariadb-admin ping -h 127.0.0.1 -u"$SQL_USER" -p"$SQL_PASSWORD"'   # "mysqld is alive"
docker compose --profile bonus exec redis redis-cli ping                                              # "PONG"
```

## 7. Common problems

- **The domain does not open:** check the `/etc/hosts` entry (correct VM IP), that port `443` is free, then `make ps` and `make logs`.
- **Browser certificate warning:** expected, the certificate is self-signed.
- **WordPress cannot reach the database:** read the `mariadb` and `wordpress` logs and check that the `SQL_*` values in `.env` are consistent.
- **A container keeps restarting:** `cd srcs && docker compose --profile bonus logs --tail=100 <service>`.