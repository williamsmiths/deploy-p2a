#!/bin/sh
set -e

# If running as root, fix permissions then re-exec as 'postgres'
if [ "$(id -u)" = "0" ]; then
  # Best-effort fix ownership and mode for data dir
  chown -R 999:999 /var/lib/postgresql/data 2>/dev/null || true
  chmod 0700 /var/lib/postgresql/data 2>/dev/null || true
  exec gosu postgres sh "$0" "$@"
fi

# Ensure password is available for psql/pg_basebackup
export PGPASSWORD="${POSTGRES_PASSWORD}"

# Wait until master is ready
until pg_isready -h master -p 5432 -U "${POSTGRES_USER}"; do
  echo "Waiting for master to be ready..."
  sleep 1
done

# Initial base backup if data directory is empty
if [ -z "$(ls -A /var/lib/postgresql/data/pgdata 2>/dev/null)" ]; then
  echo "Starting initial base backup..."
  rm -rf /var/lib/postgresql/data/*
  pg_basebackup -h master -p 5432 -D /var/lib/postgresql/data/pgdata -U "${POSTGRES_USER}" -v -P -R -X stream -C -S replica1
fi

# Ensure strict directory permissions (required by PostgreSQL)
chmod 0700 /var/lib/postgresql/data/pgdata 2>/dev/null || true

exec postgres -c config_file=/etc/postgresql/postgresql.conf