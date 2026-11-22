#!/bin/sh
set -eu
PROJECT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
DB_NAME=${PGDATABASE:-hr_analytics_db}
PSQL_BIN=${PSQL_BIN:-psql}
cd "$PROJECT_ROOT"
"$PSQL_BIN" -X -v ON_ERROR_STOP=1 -d "$DB_NAME" -f sql/01_schema_setup.sql
scripts/import_hr_csv.sh
"$PSQL_BIN" -X -v ON_ERROR_STOP=1 -d "$DB_NAME" -f sql/02_data_cleaning.sql
"$PSQL_BIN" -X -v ON_ERROR_STOP=1 -d "$DB_NAME" -f sql/03_analytical_queries.sql
"$PSQL_BIN" -X -v ON_ERROR_STOP=1 -d "$DB_NAME" -f sql/04_verification.sql > data/processed/sql_verification.txt
cat data/processed/sql_verification.txt
scripts/export_hr_csv.sh
