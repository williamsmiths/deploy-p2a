#!/bin/sh
set -e

REPL_USER=${POSTGRES_REPLICATION_USER:-replicator}
MASTER_HOST=${POSTGRES_MASTER_HOST:-postgres-research-master}
MASTER_PORT=${POSTGRES_MASTER_PORT:-5432}

if [ -z "$POSTGRES_REPLICATION_PASSWORD" ]; then
  echo "Error: POSTGRES_REPLICATION_PASSWORD is required for slave" 1>&2
  exit 1
fi

echo "[slave] waiting for master ${MASTER_HOST}:${MASTER_PORT}..."
until pg_isready -h "$MASTER_HOST" -p "$MASTER_PORT" -U "$REPL_USER" >/dev/null 2>&1; do
  sleep 2
done

# Initialize data directory from master if it's empty
if [ ! -s "$PGDATA/PG_VERSION" ]; then
  echo "[slave] syncing base backup from master"
  rm -rf "$PGDATA"/*
  export PGPASSWORD="$POSTGRES_REPLICATION_PASSWORD"
  if command -v gosu >/dev/null 2>&1; then
    gosu postgres pg_basebackup -h "$MASTER_HOST" -p "$MASTER_PORT" -D "$PGDATA" -U "$REPL_USER" -Fp -Xs -P -R
  else
    pg_basebackup -h "$MASTER_HOST" -p "$MASTER_PORT" -D "$PGDATA" -U "$REPL_USER" -Fp -Xs -P -R
  fi
  chown -R postgres:postgres "$PGDATA"
  chmod 700 "$PGDATA"
fi

# Allow additional primary_conninfo options through env
if [ -n "$POSTGRES_PRIMARY_CONNINFO_OPTS" ]; then
  echo "primary_conninfo = 'host=$MASTER_HOST port=$MASTER_PORT user=$REPL_USER password=$POSTGRES_REPLICATION_PASSWORD $POSTGRES_PRIMARY_CONNINFO_OPTS'" >> "$PGDATA/postgresql.auto.conf"
fi

exec docker-entrypoint.sh postgres -c config_file=/etc/postgresql/postgresql.conf
