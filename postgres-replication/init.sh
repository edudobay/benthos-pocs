#!/usr/bin/env bash

docker compose up -d postgres
docker compose run --rm -e PGHOST=postgres -v $PWD/source_db.sql:/db.sql:ro postgres psql -f /db.sql
docker compose run --rm -e PGHOST=postgres postgres createdb dbtarget
docker compose run --rm -e PGHOST=postgres -v $PWD/target_db.sql:/db.sql:ro postgres psql -f /db.sql dbtarget
