#!/bin/bash
# OpenProject all-in-one on Railway, with the database on Railway Postgres.
#
# The image seeds an administrator with login 'admin' on the first boot. Upstream falls back
# to the well-known password 'admin' when no password is configured, so this wrapper always
# hands the seeder a usable one (STANDARD 8.29 / round-13 lesson):
#
#   ADMIN_PASSWORD        password of 'admin' (10-128 characters: OpenProject's minimum is 10)
#   ADMIN_EMAIL           e-mail of the seeded administrator
#   ADMIN_PASSWORD_RESET  true = set the password of 'admin' to ADMIN_PASSWORD on this boot
#
# An unusable ADMIN_PASSWORD on the first boot locks the administrator with a random password
# nobody knows (the deploy still succeeds); a valid one on a later boot unlocks it.
# Then the image's own entrypoint runs: migrations + seed, then supervisord (Apache on 80,
# Puma on 8080, good_job worker, Hocuspocus, memcached).
set -uo pipefail

log() { printf '[railway-start] %s\n' "$*"; }

STATE_DIR="${APP_DATA_PATH:-/var/openproject/assets}/.railway"
LOCK_MARKER="${STATE_DIR}/admin-locked"
MIN_PASSWORD=10
MAX_PASSWORD=128

password_ok() { [ "${#1}" -ge "${MIN_PASSWORD}" ] && [ "${#1}" -le "${MAX_PASSWORD}" ] && [[ "$1" != *[[:cntrl:]]* ]]; }

configure_basics() {
  # Puma listens on PORT and Apache proxies to 8080; any other value would break the proxy.
  if [ "${PORT:-8080}" != 8080 ]; then
    log "WARNING: PORT='${PORT}' ignored; OpenProject's web server must listen on 8080 (Apache proxies to it)."
  fi
  export PORT=8080

  local host="${OPENPROJECT_HOST__NAME:-}"
  if ! [[ "${host}" =~ ^[A-Za-z0-9.-]+(:[0-9]{1,5})?$ ]]; then
    log "WARNING: OPENPROJECT_HOST__NAME='${host}' is not a host name; using ${RAILWAY_PUBLIC_DOMAIN:-localhost}."
    export OPENPROJECT_HOST__NAME="${RAILWAY_PUBLIC_DOMAIN:-localhost}"
  fi

  local workers="${OPENPROJECT_WEB_WORKERS:-2}"
  if ! [[ "${workers}" =~ ^[0-9]{1,2}$ ]] || [ "${workers}" -gt 16 ]; then
    log "WARNING: OPENPROJECT_WEB_WORKERS='${workers}' is not 0-16; using 2."
    export OPENPROJECT_WEB_WORKERS=2
  fi

  if [ -z "${SECRET_KEY_BASE:-}" ] || [ "${SECRET_KEY_BASE}" = OVERWRITE_ME ]; then
    mkdir -p "${STATE_DIR}"
    [ -s "${STATE_DIR}/secret_key_base" ] || head -c 48 /dev/urandom | od -An -tx1 | tr -d ' \n' > "${STATE_DIR}/secret_key_base"
    SECRET_KEY_BASE="$(cat "${STATE_DIR}/secret_key_base")"
    export SECRET_KEY_BASE
    log "WARNING: SECRET_KEY_BASE was empty; using a generated key stored on the volume."
  fi

  # Without SERVER_NAME, Apache serves every host name (Railway domain and custom domains).
  unset SERVER_NAME
}

configure_admin() {
  local pw="${ADMIN_PASSWORD:-}" email="${ADMIN_EMAIL:-}"
  mkdir -p "${STATE_DIR}"
  chmod 0700 "${STATE_DIR}"

  if ! [[ "${email}" =~ ^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$ ]]; then
    log "WARNING: ADMIN_EMAIL is not an e-mail address; using admin@example.com (change it in OpenProject later)."
    email="admin@example.com"
  fi
  export OPENPROJECT_SEED__ADMIN__USER__MAIL="${email}"
  export OPENPROJECT_SEED__ADMIN__USER__PASSWORD__RESET=false
  export OPENPROJECT_SEED__ADMIN__USER__LOCKED=false

  # The seeder creates 'admin' only while no administrator exists, so the configured password
  # can be passed on every boot. It must never be empty: upstream would fall back to 'admin'.
  if password_ok "${pw}"; then
    export OPENPROJECT_SEED__ADMIN__USER__PASSWORD="${pw}"
  else
    OPENPROJECT_SEED__ADMIN__USER__PASSWORD="$(head -c 48 /dev/urandom | od -An -tx1 | tr -d ' \n')"
    export OPENPROJECT_SEED__ADMIN__USER__PASSWORD
    touch "${LOCK_MARKER}"
    log "WARNING: ADMIN_PASSWORD must have ${MIN_PASSWORD}-${MAX_PASSWORD} characters. If the administrator 'admin' is created on this boot, it is LOCKED with a random password. Set a valid ADMIN_PASSWORD and redeploy to unlock it."
    return
  fi

  if [ "${ADMIN_PASSWORD_RESET:-false}" = true ] || [ -e "${LOCK_MARKER}" ]; then
    set_password_in_background "${pw}" &
  fi
}

# Runs next to supervisord: waits until the web process is healthy, then sets the password.
set_password_in_background() {
  local pw="$1" waited=0
  until curl -fsS -o /dev/null --max-time 5 http://127.0.0.1:8080/health_checks/default; do
    if [ "${waited}" -ge 1800 ]; then
      log "WARNING: OpenProject did not become healthy within 30 minutes; admin password unchanged."
      return
    fi
    sleep 10
    waited=$((waited + 10))
  done
  if (cd /app && RAILWAY_ADMIN_PASSWORD="${pw}" HOME=/home/app \
        setpriv --reuid app --regid "$(id -g app)" --init-groups \
        bundle exec rails runner /app/docker/prod/railway-admin.rb 2>&1 | grep '^\[railway-admin\]'); then
    rm -f "${LOCK_MARKER}"
    log "Set ADMIN_PASSWORD_RESET back to false."
  fi
}

main() {
  cd /app || exit 1
  if [ -z "${DATABASE_URL:-}" ] || [[ "${DATABASE_URL}" == *@127.0.0.1* ]]; then
    log "WARNING: DATABASE_URL does not point to the Postgres service; the image would start its own database inside this container."
  fi
  configure_basics
  configure_admin
  log "starting OpenProject (migrations and seed run first; the first boot takes several minutes)"
  exec /app/docker/prod/entrypoint.sh ./docker/prod/supervisord
}

main "$@"
