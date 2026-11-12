# Inception

*Projet réalisé dans le cadre du cursus 42 par msingh.*

Une petite infrastructure web isolée, montée avec **Docker Compose**. Chaque service tourne dans son propre conteneur, construit à partir d'une image de base Debian `bookworm` avec des Dockerfiles écrits à la main (aucune image applicative toute faite pour la partie obligatoire).

**Partie obligatoire :** NGINX (seul point d'entrée public, HTTPS sur le port `443`, TLS 1.2/1.3) → WordPress avec PHP-FPM → MariaDB. Les trois services sont reliés par un réseau bridge dédié, et la base de données comme les fichiers du site sont persistants.

**Bonus** (profil Compose `bonus`) : Redis (cache objet de WordPress), FTP (vsftpd) vers les fichiers WordPress, un site statique, Adminer (interface pour la base) et Dozzle (visualiseur de logs des conteneurs).

| Service | Profil | Ports exposés | Données persistantes |
|---|---|---|---|
| NGINX | core | `443` | partage le volume WordPress |
| WordPress / PHP-FPM | core | aucun (`9000` en interne) | `/home/msingh/data/wordpress` |
| MariaDB | core | aucun (`3306` en interne) | `/home/msingh/data/mariadb` |
| Redis | bonus | aucun (`6379` en interne) | aucune |
| FTP | bonus | `21`, `40000-40010` | partage le volume WordPress |
| Site statique | bonus | `8080` | aucune |
| Adminer | bonus | `8081` | aucune |
| Dozzle | bonus | `8082` | aucune |

## Utilisation

**Prérequis :** une VM Linux, Docker Engine avec Compose v2, GNU Make et `sudo` (pour `/etc/hosts` et `/home/msingh/data`).

```bash
echo "127.0.0.1 msingh.42.fr" | sudo tee -a /etc/hosts   # depuis une autre machine : IP de la VM
# puis créer srcs/.env (liste des variables dans DEV_DOC.md)
```

```bash
make          # stack obligatoire
make bonus    # stack obligatoire + services bonus
make stop     # arrête les conteneurs (make start / make start_bonus pour relancer)
make down     # supprime conteneurs et réseau (les données sont gardées)
make fclean   # DESTRUCTIF : supprime aussi images, volumes et /home/msingh/data
```

- Site : `https://msingh.42.fr` (certificat auto-signé : l'avertissement du navigateur est normal)
- Administration : `https://msingh.42.fr/wp-admin`
- Bonus : site statique `:8080`, Adminer `:8081`, Dozzle `:8082`, FTP `:21`

Procédures détaillées : [USER_DOC.md](USER_DOC.md) (utilisation) et [DEV_DOC.md](DEV_DOC.md) (installation, commandes, données).

## Organisation

```text
.
├── Makefile                 # point d'entrée : encapsule docker compose
├── secrets/                 # fichiers vides réservés à une future migration vers les secrets Docker
└── srcs/
    ├── .env                 # domaine, base, WordPress, FTP (ignoré par git)
    ├── docker-compose.yml   # services, réseau, volumes, profil bonus
    └── requirements/
        ├── mariadb/  nginx/  wordpress/      # Dockerfile + conf/ + tools/
        └── bonus/  redis/  ftp/  website/  adminer/  dozzle/
```

### Choix de conception

- Un processus principal par conteneur, lancé au premier plan (pas de `tail -f` ni de boucle infinie), sur des images Debian personnalisées. Les services se trouvent par leur nom (`mariadb`, `wordpress`, `redis`).
- NGINX est le seul port publié de la stack obligatoire. WordPress et MariaDB ne sont joignables que sur le réseau Docker.
- Initialisation automatique : `init-db.sh` crée la base et l'utilisateur MariaDB, `auto_config.sh` télécharge et installe WordPress avec WP-CLI puis crée les comptes. Les scripts sont idempotents : un redémarrage ne réinstalle rien.
- `restart: unless-stopped` sur chaque service. Les services bonus sont isolés derrière le profil `bonus`.

## Notions clés

**Machines virtuelles ou Docker.** Une VM virtualise le matériel et fait tourner un OS complet avec son propre noyau : isolation plus forte, mais plus lourde et plus lente à démarrer. Un conteneur partage le noyau de l'hôte et isole processus, système de fichiers et réseau : plus léger, plus rapide et facile à reproduire. *Ici*, la VM fournit l'hôte Linux et Docker isole les services à l'intérieur.

**Secrets ou variables d'environnement.** Les variables d'environnement sont pratiques pour la configuration, mais elles sont visibles dans l'environnement du conteneur et faciles à divulguer. Les secrets Docker sont montés comme fichiers, uniquement pour les services qui en ont besoin, et conviennent aux mots de passe. *Ici*, les identifiants sont lus depuis `srcs/.env` via `env_file` (ignoré par git). Le dossier `secrets/` ne contient que des fichiers vides prévus pour une migration ultérieure.

**Réseau Docker ou réseau de l'hôte.** Le réseau de l'hôte supprime l'isolation : les ports du conteneur sont exposés directement. Un réseau bridge donne aux conteneurs un réseau privé avec DNS intégré, et seuls les ports explicitement publiés sont accessibles. *Ici*, tous les services partagent le réseau bridge `inception`. `network: host` n'est pas utilisé.

**Volumes Docker ou bind mounts.** Les volumes sont gérés par Docker et désignés par leur nom. Les bind mounts associent un chemin explicite de l'hôte et dépendent de son existence et de ses permissions. *Ici*, `wordpress` et `mariadb` sont des volumes Compose nommés configurés avec des options de bind : les services utilisent des noms de volume, mais les données vivent dans `/home/msingh/data/`.

## Ressources

- Docker : [Engine](https://docs.docker.com/engine/), [Compose](https://docs.docker.com/compose/), [référence du fichier Compose](https://docs.docker.com/reference/compose-file/), [réseau](https://docs.docker.com/compose/how-tos/networking/), [stockage](https://docs.docker.com/engine/storage/), [secrets](https://docs.docker.com/compose/how-tos/use-secrets/)
- [NGINX](https://nginx.org/en/docs/), [PHP-FPM](https://www.php.net/manual/en/install.fpm.php), [WordPress](https://developer.wordpress.org/), [WP-CLI](https://developer.wordpress.org/cli/commands/), [MariaDB](https://mariadb.com/docs/server/)
- Bonus : [Redis](https://redis.io/docs/latest/), [Adminer](https://www.adminer.org/), [vsftpd](https://security.appspot.com/vsftpd.html), [Dozzle](https://dozzle.dev/)

### Usage de l'IA

L'IA a servi à lire les fichiers du projet, puis à rédiger, raccourcir et mettre à jour `README.md`, `USER_DOC.md` et `DEV_DOC.md`, et à vérifier la cohérence des ports, chemins, cibles du Makefile et relations entre services avec les sources. Elle n'a pas été utilisée pour écrire ni modifier les Dockerfiles, les scripts ou la configuration Compose.
