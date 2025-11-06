#!/usr/bin/env sh
set -eu

MASTER_HOST="postgres-core-master"
MASTER_PORT="5432"
REPL_USER="replicator"
REPL_PASSWORD="Kx9mP2A2024Replicator7nQ8vR3s"

echo "[slave] waiting for master ${MASTER_HOST}:${MASTER_PORT}..."
until pg_isready -h "$MASTER_HOST" -p "$MASTER_PORT" -U "$REPL_USER" >/dev/null 2>&1; do
  sleep 2
done

echo "[slave] cleaning PGDATA and syncing base backup"
rm -rf "$PGDATA"/*

echo "[slave] running basebackup as postgres"
export PGPASSWORD="$REPL_PASSWORD"
gosu postgres pg_basebackup -h "$MASTER_HOST" -p "$MASTER_PORT" -U "$REPL_USER" -D "$PGDATA" -Fp -Xs -P -R

echo "[slave] start postgres"
exec docker-entrypoint.sh postgres -c config_file=/etc/postgresql/postgresql.conf


