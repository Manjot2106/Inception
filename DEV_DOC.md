# Inception – Developer Documentation

How to set up, build, run and maintain the stack, and where its data lives.

## 1. Layout and architecture

```text
.
├── Makefile                  # wraps `docker compose -f srcs/docker-compose.yml`
├── .gitignore                # ignores srcs/.env
├── secrets/                  # empty placeholder files (see 3.3)
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/  nginx/  wordpress/          # Dockerfile, conf/, tools/
        └── bonus/  redis/  ftp/  website/  adminer/  dozzle/
```

```text
Browser ─HTTPS 443→ NGINX ─FastCGI wordpress:9000→ WordPress/PHP-FPM ─SQL mariadb:3306→ MariaDB
```

All containers join the bridge network `inception` (Docker name `srcs_inception`) and reach each other by service name. Only NGINX publishes a port in the core stack. The `bonus` profile adds Redis, FTP, the static site, Adminer and Dozzle (the latter runs the official `amir20/dozzle:v8` image and reads `/var/run/docker.sock` read-only).

## 2. Prerequisites

Linux VM, Docker Engine, Docker Compose v2, GNU Make, Git, and `sudo` (for `/etc/hosts` and `/home/msingh/data`).

```bash
docker --version && docker compose version && make --version
```

## 3. Configuration from scratch

### 3.1 Clone and map the domain

```bash
git clone <repository-url> inception && cd inception
echo "127.0.0.1 msingh.42.fr" | sudo tee -a /etc/hosts     # VM IP for remote clients
```

### 3.2 Create `srcs/.env`

```dotenv
DOMAIN_NAME=msingh.42.fr

SQL_DATABASE=wordpress
SQL_USER=<db-user>
SQL_PASSWORD=<strong-password>
SQL_ROOT_PASSWORD=<strong-password>

WP_TITLE=Inception
WP_ADMIN_USER=<admin-login>            # must not contain "admin"
WP_ADMIN_PASSWORD=<strong-password>
WP_ADMIN_EMAIL=<email>
WP_USER=<author-login>
WP_USER_PASSWORD=<strong-password>
WP_USER_EMAIL=<email>

FTP_USER=<ftp-login>                   # keep equal to the login used in the compose FTP mount path
FTP_PASSWORD=<strong-password>
```

Then `chmod 600 srcs/.env`. The file is git-ignored; never commit real values.

**Login-specific values to change for another login** (keep them consistent):

| File | Value |
|---|---|
| `Makefile` | `DATA_PATH = /home/msingh/data` |
| `srcs/docker-compose.yml` | volume `device:` paths under `/home/msingh/data/…` and the FTP mount `/home/msingh/ftp/wordpress` |
| `srcs/.env` | `DOMAIN_NAME` |
| `srcs/requirements/nginx/conf/nginx.conf` | `server_name` |
| `srcs/requirements/nginx/Dockerfile` | certificate subject (`CN=…`, `UID=…`) |

### 3.3 Secrets

The current stack reads its passwords from `srcs/.env` through `env_file`; it does **not** use Docker secrets yet. `secrets/` holds three empty placeholder files (`db_password.txt`, `db_root_password.txt`, `credentials.txt`) that are not referenced by `docker-compose.yml`. Migrating means: declare them in a top-level `secrets:` section, grant each to the services that need it, read `/run/secrets/<name>` in `init-db.sh`, `auto_config.sh` and the FTP entrypoint, and add `secrets/` to `.gitignore` before writing real values.

## 4. Build and launch

### Makefile (repository root)

| Target | Action |
|---|---|
| `make` / `make up` | create `/home/msingh/data/{mariadb,wordpress}`, build, start the core stack |
| `make bonus` | same and the `bonus` profile |
| `make stop`, `make start`, `make start_bonus` | stop all / start core / start core + bonus (existing containers) |
| `make down` | remove containers and network, keep data |
| `make ps`, `make ps_bonus`, `make logs`, `make logs_bonus` | status and logs (core / with bonus) |
| `make clean` | `down --remove-orphans` |
| `make fclean` | ⚠️ `down -v --rmi all`, then delete `mariadb` and `wordpress` data directories |
| `make re`, `make re_bonus` | `fclean` then rebuild (core / with bonus) |

### Docker Compose directly (run from `srcs/`)

The Compose project name is `srcs`, so objects are prefixed `srcs_`.

```bash
cd srcs
docker compose up -d --build                       # core; add --profile bonus for everything
docker compose --profile bonus config              # validate and render the configuration
docker compose build --no-cache nginx              # rebuild one image
docker compose up -d --build --no-deps wordpress   # recreate one service after a change
docker compose restart nginx
docker compose logs -f --tail=200 wordpress
docker compose exec wordpress bash                 # shell in a container
docker compose exec nginx nginx -t                 # check NGINX configuration
docker network inspect srcs_inception
```

## 5. Data storage and persistence

| Compose volume | In container | On the host | Used by |
|---|---|---|---|
| `wordpress` | `/var/www/wordpress` (FTP: `/home/msingh/ftp/wordpress`) | `/home/msingh/data/wordpress` | wordpress, nginx, ftp |
| `mariadb` | `/var/lib/mysql` | `/home/msingh/data/mariadb` | mariadb |

These are named volumes created with the `local` driver and bind options, so the files sit at fixed host paths (the directories must exist: the Makefile creates them). Redis, Adminer, Dozzle and the static site store nothing.

```bash
docker volume ls --filter name=srcs
docker volume inspect srcs_wordpress srcs_mariadb
sudo du -sh /home/msingh/data/*
```

Persistence rules:

- `down`, image rebuilds and container recreation keep the data.
- `down -v` removes the volume objects, but the host directories remain.
- `make fclean` / `make re` delete the host directories: a full reset.
- Reset a single dataset (WordPress or database) only with the stack stopped, and prefer a full reset, because resetting only one side leaves WordPress and MariaDB inconsistent.

## 6. Initialization behavior

- **MariaDB** (`tools/init-db.sh`): initializes `/var/lib/mysql` only if empty, starts a temporary server without networking, then creates the database and user and re-applies `SQL_PASSWORD` on every start, and finally runs `mariadbd` in the foreground.
- **WordPress** (`tools/auto_config.sh`): waits for MariaDB, then downloads WordPress, creates `wp-config.php`, installs the site and creates the author user, each only if missing; it also installs and enables the Redis cache plugin (active only when the bonus Redis is running), then starts PHP-FPM in the foreground.
- **NGINX**: a self-signed certificate (RSA 2048, 365 days) is generated at image build time; TLS 1.2/1.3 only.
- **Credential changes on an existing install:** WordPress user passwords are applied only at first install (change them in the admin panel). To change `SQL_PASSWORD`, update both `.env` and `DB_PASSWORD` in `/home/msingh/data/wordpress/wp-config.php`, then `make down && make`. Otherwise use `make re`.

## 7. Known limitations

- Passwords are stored in plaintext in `srcs/.env` (no Docker secrets yet).
- `SQL_ROOT_PASSWORD` is declared but never applied to the MariaDB root account.
- Redis runs with `--protected-mode no`; it is safe only because its port is not published.
- Dozzle is published on `8082` without authentication and has read access to the Docker socket: use it only in a local environment.

## 8. Quick troubleshooting

- **Mount path does not exist:** `make prepare_bonus`, and check that `DATA_PATH` matches the `device:` paths.
- **Port already in use:** `sudo ss -lntp | grep -E ':(443|21|808[0-2])\b'`.
- **`502 Bad Gateway`:** `docker compose ps wordpress` and its logs; PHP-FPM must listen on `0.0.0.0:9000`.
- **MariaDB re-initializes at each start:** check that `/home/msingh/data/mariadb/mysql` persists and is accessible.