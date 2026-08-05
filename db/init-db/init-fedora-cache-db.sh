#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
  CREATE ROLE fedora_cache LOGIN PASSWORD '$FEDORA_DB_PASSWORD';
  CREATE DATABASE fcrepo_cache WITH ENCODING='UTF8';
  GRANT ALL PRIVILEGES ON DATABASE fcrepo_cache TO fedora_cache;
EOSQL