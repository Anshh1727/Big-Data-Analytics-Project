#!/bin/sh
set -eu
PROJECT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$PROJECT_ROOT"
scripts/run_sql_pipeline.sh
Rscript r_scripts/eda_and_preprocessing.R
Rscript r_scripts/predictive_model.R
printf '%s\n' 'SQL and R stages completed. Build and validate the Tableau workbook using docs/tableau_setup_guide.md.'
