# OpenProject for Railway: the official all-in-one image (web, background worker, Hocuspocus
# for collaborative editing, memcached and the Apache proxy under supervisord) with the
# database on Railway Postgres. A start wrapper validates the admin settings so the seeded
# admin never gets the well-known default password.
#
# Pinned by tag and digest. To upgrade, change both to a newer release:
# https://hub.docker.com/r/openproject/openproject/tags (release notes: https://www.openproject.org/docs/release-notes/)
FROM openproject/openproject:17.9.8@sha256:2d9a77fd8b7781ee3fea84ac232dd449c21ac4f84720b2e3019e8b1a0003684e

COPY --chmod=0755 railway-start.sh /app/docker/prod/railway-start
COPY --chmod=0644 railway-admin.rb /app/docker/prod/railway-admin.rb

RUN bash -n /app/docker/prod/railway-start \
 && ruby -c /app/docker/prod/railway-admin.rb >/dev/null \
 && command -v supervisord apache2ctl memcached curl >/dev/null

ENTRYPOINT ["/app/docker/prod/railway-start"]
