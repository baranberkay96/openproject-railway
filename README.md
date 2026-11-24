# Deploy and Host OpenProject with Railway

OpenProject is open-source project management software: work packages, Gantt charts, agile boards, wikis, meetings, time and cost tracking, and team planning. This community template runs OpenProject 17.9.8 Community Edition with PostgreSQL 17 and creates the administrator with a generated password, so the well-known default login is never active.

## About Hosting OpenProject

OpenProject is a Ruby on Rails application with several processes: the Puma web server, a background job worker (good_job) for e-mails, notifications and exports, Hocuspocus for collaborative editing, memcached and an Apache proxy. This template runs the official all-in-one image, which starts all of them under supervisord in one service, and connects it to Railway Postgres instead of the image's internal database. Attachments and uploaded files are stored on a Railway volume. On the first boot the image migrates the database and seeds base data, demo projects and the administrator; this wrapper always passes a validated password, because upstream falls back to `admin`/`admin` when none is set.

## Common Use Cases

- Project portfolio and classic project management with Gantt charts and baselines
- Agile and Scrum teams with backlogs, sprints and boards
- A self-hosted Jira or MS Project alternative with time and cost tracking
- Meeting agendas, minutes and project wikis in one place

## Dependencies for OpenProject Hosting

- OpenProject 17.9.8 (official all-in-one image `openproject/openproject`, pinned by digest)
- PostgreSQL 17 (Railway's `postgres-ssl` image)

### Deployment Dependencies

- OpenProject documentation: https://www.openproject.org/docs/
- Docker installation guide: https://www.openproject.org/docs/installation-and-operations/installation/docker/
- Environment configuration: https://www.openproject.org/docs/installation-and-operations/configuration/environment/
- Source code: https://github.com/opf/openproject

### Implementation Details

| Service | Role | Public |
|---|---|---|
| OpenProject | Web (Puma on 8080), background worker, Hocuspocus, memcached and Apache on 80 under supervisord; volume `/var/openproject/assets` for attachments | HTTPS domain (Apache) |
| Postgres | All OpenProject data; private only, with a volume | no |

**First login**

1. Wait until the OpenProject service is healthy (`/health_checks/default`). The first boot runs all database migrations and the seed, which takes several minutes.
2. Copy `ADMIN_PASSWORD` from the OpenProject service's Variables. The login is `admin`.
3. Open the public domain and sign in. You are not asked to change the password; change the administrator's e-mail address (default `admin@example.com`) under My account.

A password shorter than 10 characters (OpenProject's minimum) never breaks the deploy: the administrator is locked with a random password until you set a valid `ADMIN_PASSWORD` and redeploy. Forgot the password? Set a new `ADMIN_PASSWORD` and `ADMIN_PASSWORD_RESET=true`, redeploy, then set it back to `false`. After the first boot, user accounts and self-registration are managed in Administration > Authentication.

**Custom domain.** Add it in the service's Settings > Networking, then set `OPENPROJECT_HOST__NAME` to it and redeploy (links, e-mails and collaborative editing use it).

**E-mail.** Configure it in Administration > E-mails and notifications. Railway allows outbound SMTP only on the Pro plan.

**Configuration.** Any OpenProject setting can be set as an `OPENPROJECT_*` variable (see the environment configuration guide), for example `OPENPROJECT_DEFAULT__LANGUAGE=de`. Keep `SECRET_KEY_BASE` unchanged after the first boot.

**Resources and plans.** OpenProject is a heavy application. Measured on Railway (2026-11-24): about 1.5-2 GB of RAM at idle for the OpenProject service with 2 web workers, and about 0.1 GB for Postgres, so expect roughly $18-25 a month. It does not fit Trial or Free plans (1 GB per service); use Hobby or Pro.

**Scaling.** Raise `OPENPROJECT_WEB_WORKERS` (each worker needs about 300-400 MB) together with the service's memory. The service runs as one replica because attachments are on its volume.

**Backups.** Use Railway's volume backups for the Postgres and OpenProject volumes, or a `pg_dump` of the database plus a copy of `/var/openproject/assets`.

**Upgrading.** The version is pinned in `services/openproject/Dockerfile` (tag and digest). Migrations run automatically on start; back up before upgrading and read the release notes.

**License.** OpenProject Community Edition is free software under GPL-3.0. Enterprise add-ons require a license from OpenProject GmbH. This is a community template, not affiliated with or endorsed by OpenProject GmbH.

### Why Deploy OpenProject on Railway?

Railway runs OpenProject and its Postgres database in one project with a private network, an HTTPS domain, persistent volumes, logs and usage-based pricing. This template gives you a secured, production-style OpenProject in a few minutes, with the administrator protected from the start and no manual server setup.
