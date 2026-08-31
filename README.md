# DockForge PHP Stack

**Current version: 1.0.0**

DockForge PHP Stack is a reproducible multi-application PHP environment for local development and Docker-based deployments. It provides:

- Apache and PHP, switchable from PHP 7.4 through PHP 8.4
- MariaDB 12.3.3
- phpMyAdmin 5.2.3
- Apache `mod_rewrite` and `mod_headers`
- The PHP `mysqli`, Redis, and OPcache extensions
- A Redis 7 service with a health check
- Optional application request profiling through response headers and logs
- MariaDB slow-query logging and Performance Schema
- Automatic database initialization from an SQL dump
- Support for multiple applications under the `public` directory
- Compatibility with Intel and Apple Silicon hosts

## Requirements

- Docker Desktop, or Docker Engine with Docker Compose v2
- Ports `80`, `3306`, and `8081` available on the host, unless changed in `.env`

Verify the installation:

```sh
docker --version
docker compose version
```

## Version information

The canonical release version is stored in the root `VERSION` file. The same version is attached to every container through the `com.dockforge.stack.version` label.

Display the repository version:

```sh
cat VERSION
```

Display the version label of a running service:

```sh
docker compose ps -q web | xargs docker inspect \
  --format '{{ index .Config.Labels "com.dockforge.stack.version" }}'
```

`STACK_VERSION` in `.env` may override the container label for a packaged release. Keep it synchronized with `VERSION` when publishing a new DockForge release.

## Project layout

Apache serves the entire `public` directory as its document root. Each application must have its own directory under `public`:

```text
.
├── Dockerfile
├── docker-compose.yaml
├── .env.example
├── database
│   └── init
│       └── .gitkeep
└── public
    ├── php.ini
    ├── my.cnf
    ├── MyApp
    │   ├── index.php
    │   └── .htaccess
    └── MyOtherApp
        └── index.php
```

Applications are available by directory name:

- `public/MyApp` → <http://localhost/MyApp>
- `public/MyOtherApp` → <http://localhost/MyOtherApp>

The root URL, <http://localhost>, intentionally does not open an application directly. It returns HTTP 403 unless a `public/index.php` or `public/index.html` file is added.

## Quick start

Clone the repository and start the services:

```sh
git clone https://github.com/ourdomain72/docker_config.git
cd docker_config
docker compose up -d --build
```

The stack has development defaults, so `.env` is optional for a first local run. To customize ports, versions, database names, or credentials, create it before starting:

```sh
cp .env.example .env
docker compose up -d --build
```

The repository provides the Docker runtime, not a complete application checkout. Put each application in its own directory under `public` (for example `public/MyApp`) before opening its URL. Locally present application directories that are ignored or untracked by Git are not included when another user clones this repository.

The initial MariaDB startup can take longer when initialization files are supplied in `database/init`.

Check service status:

```sh
docker compose ps
```

## Local URLs

| Service | URL |
| --- | --- |
| Example application | <http://localhost/MyApp> |
| phpMyAdmin | <http://localhost:8081> |
| Apache root | <http://localhost> (403 by design) |

## Default credentials

These credentials are intended only for local development. Change them before using this configuration on a shared machine, public server, or production environment.

### phpMyAdmin login

Open <http://localhost:8081> and use:

| Field | Default value |
| --- | --- |
| Server | `db` (normally selected automatically) |
| Username | `user` |
| Password | `user_password` |

The MariaDB root account can also be used locally:

| Field | Default value |
| --- | --- |
| Username | `root` |
| Password | `root_password` |

### Application database connection

Containers communicate over the internal Docker network. Each application should define these values in its own `.env` file:

| Setting | Default value |
| --- | --- |
| Host | `db` |
| Port | `3306` |
| Database | `my_database` |
| Username | `user` |
| Password | `user_password` |
| Driver | `mysqli` |

The Compose file intentionally does not inject `DB_*` variables into the `web` service. This ensures that each application remains the only authority for its own database connection. Do not use `localhost` as the database host from a PHP application running inside Docker. In a container, `localhost` refers to that same container; the MariaDB service hostname is `db`.

For a database client running directly on the host machine, use:

| Setting | Default value |
| --- | --- |
| Host | `127.0.0.1` |
| Port | `3306` |
| Database | `my_database` |
| Username | `user` |
| Password | `user_password` |

## Environment variables

The stack can start without `.env` by using the development defaults shown below. Copy `.env.example` to `.env` before making local changes or deploying anywhere beyond an isolated development machine. The `.env` file is ignored by Git.

| Variable | Default | Purpose |
| --- | --- | --- |
| `STACK_VERSION` | `1.0.0` | DockForge release version attached to container labels |
| `PHP_VERSION` | `8.2` | PHP/Apache image version; supported range is 7.4–8.4 |
| `DOCKER_PLATFORM` | `linux/amd64` | Keeps legacy PHP images usable on Intel and Apple Silicon |
| `APP_PORT` | `80` | Host port for Apache |
| `PHPMYADMIN_PORT` | `8081` | Host port for phpMyAdmin |
| `APP_PROFILING` | `1` | Enables the application performance hook when the application supports it |
| `APP_SLOW_REQUEST_MS` | `500` | Logs profiled requests whose application time reaches this threshold |
| `DB_SERVER_VERSION` | `12.3.3` | Pinned MariaDB image version |
| `DB_PUBLISHED_PORT` | `3306` | MariaDB port published on the host |
| `DB_HOST` | `db` | Database hostname used inside Docker |
| `DB_PORT` | `3306` | Database port used inside Docker |
| `DB_ROOT_PASSWORD` | `root_password` | MariaDB root password |
| `DB_DATABASE` | `my_database` | Application database name |
| `DB_USERNAME` | `user` | Application database user |
| `DB_PASSWORD` | `user_password` | Application database password |
| `DB_DRIVER` | `mysqli` | PHP database driver |

Application-specific settings such as `DB_*`, `CI_ENV`, `APP_BASE_URL`, `APP_CDN_URL`, and `APP_TIMEZONE` belong in each application's own `.env` file and are not injected by Compose.

If `APP_PORT` is changed, update the base URL inside each application's `.env` to include the same port. For example:

```dotenv
APP_PORT=8080
APP_BASE_URL=http://localhost:8080/MyApp/
APP_CDN_URL=http://localhost:8080/MyApp/theme/
```

Apply environment changes by recreating the services:

```sh
docker compose up -d --build
```

## Switching PHP versions

Set `PHP_VERSION` in `.env` to any supported version from 7.4 through 8.4:

```dotenv
PHP_VERSION=8.4
```

Then rebuild the web image:

```sh
docker compose build --no-cache web
docker compose up -d
docker compose exec web php -v
```

For a one-off version test without editing `.env`:

```sh
PHP_VERSION=7.4 docker compose build web
PHP_VERSION=7.4 docker compose up -d
docker compose exec web php -v
```

Changing PHP versions does not delete the MariaDB volume.

`DOCKER_PLATFORM=linux/amd64` uses Docker Desktop emulation on Apple Silicon. This is intentional because older PHP images, especially PHP 7.4, may not provide a compatible native image for every host architecture.

## Performance features and controls

The stack enables OPcache, Redis, lightweight application profiling, and MariaDB diagnostic features by default. The controls below are independent: disabling profiling does not disable OPcache, and disabling the MariaDB slow-query log does not disable Performance Schema.

### PHP OPcache

OPcache is compiled into the web image and configured in `docker/php/opcache.ini`. Its current development settings allocate 128 MB, cache up to 20,000 PHP files, keep JIT disabled, and check file timestamps on every request so source edits are visible immediately.

Check its installed and configured state:

```sh
docker compose exec web php -r '
echo "loaded=".(extension_loaded("Zend OPcache") ? "yes" : "no").PHP_EOL;
echo "enabled=".ini_get("opcache.enable").PHP_EOL;
echo "memory=".ini_get("opcache.memory_consumption").PHP_EOL;
'
```

To disable OPcache without removing the extension, set this in `docker/php/opcache.ini`:

```ini
opcache.enable=0
```

To enable it again:

```ini
opcache.enable=1
```

Because this configuration is copied into the image, apply either change by rebuilding the web service:

```sh
docker compose up -d --build web
```

For production, timestamp validation can be disabled for slightly lower overhead:

```ini
opcache.validate_timestamps=0
```

When timestamp validation is disabled, rebuild or restart the web container after every PHP deployment. Keep it enabled for local development.

### Redis

Redis is enabled as the `redis` service in `docker-compose.yaml`. The web container receives `REDIS_HOST=redis` and `REDIS_PORT=6379`. Check it with:

```sh
docker compose exec redis redis-cli ping
docker compose exec web php -r 'echo extension_loaded("redis") ? "enabled\n" : "disabled\n";'
```

A healthy service returns `PONG`. Restart or stop Redis with:

```sh
docker compose restart redis
docker compose stop redis
```

Stopping Redis disables the server only temporarily. Applications configured to require Redis may wait, fail, or fall back to another cache. To disable Redis permanently, first configure each application to use its file/database cache or no cache; then remove the `redis` service, the web service's `REDIS_*` variables, and its Redis `depends_on` entry from `docker-compose.yaml`. Re-enable it by restoring those entries and running:

```sh
docker compose up -d redis web
```

The PHP Redis extension remains installed when the Redis service is stopped; an installed extension does not imply that an application must use it.

### Application profiling

Profiling is controlled entirely from the root `.env` file:

```dotenv
APP_PROFILING=1
APP_SLOW_REQUEST_MS=500
```

Set `APP_PROFILING=0` to disable collection and profiling response headers. Set it back to `1` to enable them. `APP_SLOW_REQUEST_MS` is the minimum application duration, in milliseconds, that is written to the application debug log. Apply changes by recreating the web container; rebuilding is unnecessary:

```sh
docker compose up -d --force-recreate web
```

When supported by the application hook, an enabled response contains headers similar to:

```text
Server-Timing: app;dur=79.04, db;dur=27.15
X-App-Query-Count: 73
```

Inspect headers and slow-request entries with:

```sh
curl -sSI http://localhost/MyApp/ | grep -Ei 'server-timing|x-app-query-count'
docker compose logs web
```

Profiling stores database query timings in memory for the duration of each request. Disable it for production unless these diagnostics are actively needed.

### MariaDB tuning and diagnostics

MariaDB is configured through `public/my.cnf`. The current defaults use a 512 MB InnoDB buffer pool, allow 100 connections, enable Performance Schema, and record queries taking at least 200 ms in MariaDB's slow-log table.

The main switches are:

| Feature | Enabled value | Disabled value |
| --- | --- | --- |
| Performance Schema | `performance_schema=ON` | `performance_schema=OFF` |
| Slow-query log | `slow_query_log=ON` | `slow_query_log=OFF` |

The slow-query threshold is controlled by:

```ini
long_query_time=0.2
```

The value is in seconds. For example, `1` records queries taking at least one second. `log_output=TABLE` stores entries in `mysql.slow_log`; use `FILE` instead if file-based log rotation is preferred.

After editing `public/my.cnf`, restart MariaDB and wait for it to become healthy:

```sh
docker compose restart db
docker compose ps
```

Confirm the live values without printing the password in the host shell:

```sh
docker compose exec db sh -lc \
  'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" -e \
  "SHOW VARIABLES WHERE Variable_name IN \
  (\"innodb_buffer_pool_size\",\"max_connections\",\"performance_schema\",\"slow_query_log\",\"long_query_time\",\"log_output\");"'
```

Read recent slow queries:

```sh
docker compose exec db sh -lc \
  'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" -e \
  "SELECT start_time,query_time,rows_examined,sql_text FROM mysql.slow_log ORDER BY start_time DESC LIMIT 20;"'
```

Performance Schema and slow logging consume some resources. Keep them enabled during diagnosis and local development; on a constrained production server, measure their impact before deciding whether to leave them enabled. Adjust `innodb_buffer_pool_size` to the host's available memory rather than copying the 512 MB value blindly.

## MariaDB initialization and persistence

MariaDB data is stored in the named Docker volume `mariadb_data`. The directory below is mounted into the official initialization directory:

```text
database/init/
```

Files ending in `.sql`, `.sql.gz`, or executable `.sh` scripts in this directory are processed automatically only when `mariadb_data` is empty. Restarting containers does not process them again and does not remove existing data. The repository includes only `.gitkeep`; supply your own dump when needed.

Inspect the database version and tables:

```sh
docker compose exec db mariadb -u root -p
```

When prompted, enter the value of `DB_ROOT_PASSWORD` from `.env`.

Import an SQL dump manually into the existing database:

```sh
docker compose exec -T db mariadb \
  -u root -p"root_password" my_database < path/to/database.sql
```

Export a backup:

```sh
docker compose exec -T db mariadb-dump \
  -u root -p"root_password" my_database > database-backup.sql
```

Avoid putting real production credentials or unreviewed production data in a public repository.

### Resetting the local database

The following command removes containers and the MariaDB volume. All local database data will be permanently deleted and the initialization dump will be imported again on the next start:

```sh
docker compose down -v
docker compose up -d --build
```

Create a backup before running this command if the local database contains anything important.

## Adding another application

1. Create a directory such as `public/MyApp`.
2. Put its `index.php` or `index.html` inside that directory.
3. Open <http://localhost/MyApp>.
4. If the application uses clean URLs, include an appropriate `.htaccess` file and use relative rewrite targets so the rules work from a subdirectory.
5. Configure its public base URL as `http://localhost/MyApp/`.
6. Use `db:3306` for its database connection from inside Docker.

Application URL and database settings belong in each application's own configuration. Multiple applications may therefore use different base URLs and databases while sharing the same Docker services.

## Common commands

Start or update all services:

```sh
docker compose up -d --build
```

Stop the services without deleting database data:

```sh
docker compose down
```

Restart a service:

```sh
docker compose restart web
docker compose restart db
docker compose restart redis
docker compose restart phpmyadmin
```

View service logs:

```sh
docker compose logs -f web
docker compose logs -f db
docker compose logs -f redis
docker compose logs -f phpmyadmin
```

Open a shell in the PHP container:

```sh
docker compose exec web bash
```

Check enabled PHP modules:

```sh
docker compose exec web php -m
```

Validate the Compose file:

```sh
docker compose config --quiet
```

## Troubleshooting

### `localhost` returns HTTP 403

This is expected. Apache serves `public`, which intentionally has no root index file. Open an application directory instead, such as <http://localhost/MyApp>.

### An application directory returns HTTP 404

- Confirm that the directory exists under `public`.
- Confirm that it contains `index.php` or `index.html`.
- Check `.htaccess` rewrite rules for root-relative targets such as `/index.php`; subdirectory applications should normally use `index.php` instead.
- Run `docker compose logs web`.

### phpMyAdmin returns HTTP 403 or does not open

- Use <http://localhost:8081>, not `http://localhost/phpmyadmin`.
- Confirm that the container is running with `docker compose ps`.
- Check `docker compose logs phpmyadmin`.
- If port 8081 is occupied, change `PHPMYADMIN_PORT` in `.env`.

### PHP cannot connect to MariaDB

- Use `db` as the host and `3306` as the internal port.
- Make sure the credentials match `.env`.
- Check that the database is healthy with `docker compose ps`.
- Review database logs with `docker compose logs db`.

### A host port is already in use

Change the relevant value in `.env`, for example:

```dotenv
APP_PORT=8080
DB_PUBLISHED_PORT=3307
PHPMYADMIN_PORT=8082
```

### Environment changes do not affect an existing database

The official MariaDB image uses initialization variables only when the data directory is empty. Changing database names or passwords in `.env` does not automatically modify an existing `mariadb_data` volume.

## Security notes

- The included usernames and passwords are development defaults and are not safe for production.
- Never expose MariaDB or phpMyAdmin publicly without appropriate network restrictions, TLS, and strong credentials.
- Keep `.env` out of version control.
- Review SQL dumps before publishing them; dumps may contain personal, confidential, or production data.
- Use secrets management instead of plain environment variables for production deployments.

## Tested configuration

The Dockerfile has been successfully built with PHP 7.4 and PHP 8.4. The active default is PHP 8.2. Apache subdirectory routing, Redis connectivity, OPcache loading, the MariaDB connection, MariaDB diagnostics, application profiling, and phpMyAdmin have been tested successfully with this stack.

```text
Example app:  http://localhost/MyApp
phpMyAdmin:   http://localhost:8081
MariaDB:      12.3.3
Redis:        7
phpMyAdmin:   5.2.3
```
