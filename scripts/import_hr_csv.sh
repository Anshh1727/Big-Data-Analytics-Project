#!/bin/sh
set -eu
PROJECT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CSV="$PROJECT_ROOT/data/raw/Extended_Employee_Performance_and_Productivity_Data.csv"
DB_NAME=${PGDATABASE:-hr_analytics_db}
PSQL_BIN=${PSQL_BIN:-psql}
if [ ! -f "$CSV" ]; then
  printf 'Required dataset not found: %s\n' "$CSV" >&2
  exit 2
fi
"$PSQL_BIN" -X -v ON_ERROR_STOP=1 -d "$DB_NAME" -c 'TRUNCATE TABLE hr_analytics.raw_hr_employees'
"$PSQL_BIN" -X -v ON_ERROR_STOP=1 -d "$DB_NAME" -c "\\copy hr_analytics.raw_hr_employees FROM '$CSV' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')"
printf '%s\n' 'Employee CSV imported to hr_analytics.raw_hr_employees.'
