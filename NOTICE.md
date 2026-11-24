# Notice

## Upstream software

This repository contains Railway configuration and a small start wrapper only. OpenProject is pulled at build time from its official container image; it is not stored in this repository.

| Software | License | Source (publisher) |
|---|---|---|
| OpenProject 17.9.8 Community Edition (all-in-one image: Puma, good_job, Hocuspocus, memcached, Apache, supervisord) | GPL-3.0 (OpenProject); bundled packages under their own licenses | `openproject/openproject:17.9.8@sha256:2d9a77fd8b7781ee3fea84ac232dd449c21ac4f84720b2e3019e8b1a0003684e` (OpenProject GmbH) |
| PostgreSQL 17 | PostgreSQL License | `ghcr.io/railwayapp-templates/postgres-ssl:17.12@sha256:647d160591a2e16d2f09c5c94f76f9ef641222a89e8175601593ea5a640f663e` (Railway; MIT-licensed image repository) |

OpenProject source for the pinned release: https://github.com/opf/openproject/tree/v17.9.8.

## Verified against

| What | Upstream file | Ref | Checked |
|---|---|---|---|
| Latest stable release | GitHub releases (`v17.9.8`, 2026-11-19), Docker Hub tags (`17` = `17.9.8`) | v17.9.8 | 2026-11-24 |
| All-in-one entrypoint, external database detection, migrate + seed, supervisord programs, Apache proxy | `docker/prod/entrypoint.sh`, `supervisord`, `supervisord.conf.erb`, `proxy`, `proxy.conf.erb`, `web`, `worker`, `Dockerfile` | v17.9.8 | 2026-11-24 |
| Seeded admin (`seed_admin_user_*`, default password `admin`, saved without validation) | `config/constants/settings/definition.rb`, `app/seeders/admin_user_seeder.rb` | v17.9.8 | 2026-11-24 |
| Password minimum 10, web workers default 2 | `config/constants/settings/definition.rb` | v17.9.8 | 2026-11-24 |
| Health checks exempt from HTTPS redirect and host check | `config/environments/production.rb`, `config/application.rb`, `config/initializers/health_checks.rb` | v17.9.8 | 2026-11-24 |
| Upstream compose stack | `opf/openproject-docker-compose` `docker-compose.yml` | stable/17 | 2026-11-24 |

## Adapted code

| Our file | Source | Changes |
|---|---|---|
| `services/openproject/railway-start.sh`, `railway-admin.rb` | Written for this template | — |

## Trademarks

"OpenProject" is a trademark of OpenProject GmbH; "Railway" and "PostgreSQL" belong to their respective owners. This is a community template and is not affiliated with or endorsed by them.
