# OpenProject 17 Community: composer spec

Listing name: **OpenProject 17 Community**
Description (71 chars): Project management: tasks, Gantt, boards, wiki, time tracking, Postgres
Category: Other. Icon: `https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/openproject.svg`
Repository: `baranberkay96/openproject-railway` (this folder is the repo root).

## Services

| Service | Source | Public | Volume | Healthcheck |
|---|---|---|---|---|
| OpenProject | repo `/services/openproject`: `FROM openproject/openproject:17.9.8@sha256:2d9a…684e` (all-in-one) + `railway-start.sh` + `railway-admin.rb` | domain → 80 (Apache) | `/var/openproject/assets` | `/health_checks/default` on `PORT` 8080 (Puma), 1200 s |
| Postgres | `ghcr.io/railwayapp-templates/postgres-ssl:17.12@sha256:647d…663e` (= `:17`; upstream recommends PostgreSQL 17) | no | `/var/lib/postgresql/data` | — |

Pinned 2026-11-24: OpenProject 17.9.8 (2026-11-19).

## Design

- All-in-one image instead of separate web/worker services: web and worker both need the attachments directory, and a Railway volume belongs to one service (STANDARD 3b). The image runs web, good_job worker, Hocuspocus, memcached and Apache under supervisord; `DATABASE_URL` pointing at Railway Postgres disables its internal Postgres.
- `PORT=8080` (Puma, healthcheck; health checks are exempt from the HTTPS redirect and host check), `targetPort` 80 (Apache: `/hocuspocus` WebSocket + app). `SERVER_NAME` unset so Apache serves every host name.
- Admin: `railway-start.sh` validates `ADMIN_PASSWORD` (10-128) and exports `OPENPROJECT_SEED__ADMIN__USER__PASSWORD`, `__PASSWORD__RESET=false`, `__MAIL`, `__LOCKED=false`. The seeder uses it only while no administrator exists, so a valid password is passed on every boot; an invalid one is replaced by a random password + lock marker on the volume, so the default `admin` can never come back. Reset/unlock: background job waits for `/health_checks/default`, then `rails runner railway-admin.rb` as the app user.

## Improvements over market templates

Market (2026-11): `openproject/openproject:14.4.2` / `15.4.2` with Postgres 16 (≈49 and ≈44 active), `openproject:17` with `RAILWAY_RUN_UID=0` and empty seed password (≈9 active).

- Current 17.9.8 pinned by digest (market: 14.x/15.x, one year+ old, or a floating tag).
- No `admin`/`admin` window: market templates leave the seed password empty, so upstream seeds `admin`/`admin` on a public URL until someone logs in.
- Healthcheck on `/health_checks/default`; Hocuspocus (collaborative editing) works through Apache on the same domain.
- Postgres 17 as upstream recommends.

## Resources

Measured on Railway, test project, 2026-11-24 (OpenProject 17.9.8, 2 web workers): OpenProject 2.5 GB idle (≈0.02 vCPU), Postgres 0.21 GB.

Estimate: ≈ 2.7 GB → ≈ $27-35/month. Minimum plan: Hobby (does not fit Trial/Free 1 GB per service).

Railway prices: RAM $10/GB-month, vCPU $20/vCPU-month, volume $0.15/GB-month.

## Verification checklist

1. Both services SUCCESS; `/health_checks/default` 200; public domain shows the login page.
2. Log in as `admin` with `ADMIN_PASSWORD` (no forced password change); `admin`/`admin` rejected.
3. Create a project and a work package with an attachment through the API v3; download the attachment.
4. `ADMIN_PASSWORD=short` + reset → warning, healthy; valid password + reset → new password works.
5. Redeploy: data and attachments persist.

## Open questions

- BIM edition and IMAP-based e-mail ingestion are not configured (IMAP: set `IMAP_ENABLED=true` and the `OPENPROJECT_IMAP_*` variables).
