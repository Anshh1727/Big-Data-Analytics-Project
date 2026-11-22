# Setup and execution guide

## 1. Source data

Place the student-downloaded file at:

```text
data/raw/Extended_Employee_Performance_and_Productivity_Data.csv
```

The repository ignores raw data. The source is synthetic; the student confirmed instructor approval for the exception. Source is attributed in `data/data_dictionary.md`. Before distributing a workbook publicly, check the current Kaggle license and terms. Do not include employee-level rows in Tableau Public.

## 2. PostgreSQL ETL

Use PostgreSQL 14+ and `psql`. Create a local database and set connection environment variables for your shell; never commit credentials. `.env.example` documents optional connection keys. Run:

```sh
PGHOST=localhost PGPORT=5432 PGDATABASE=hr_analytics_db PGUSER=postgres scripts/run_sql_pipeline.sh
```

The script creates the `hr_analytics` schema, imports CSV into text staging, validates and cleans types/ranges, loads the normalized tables, creates analytical views, runs reconciliation checks, and writes CSV extracts to `data/processed/`. The raw data and all processed files are ignored by Git. For the R analyses, install the packages into the project-local library and run:

```sh
Rscript scripts/install_r_packages.R
R_LIBS_USER="$PWD/r_lib" Rscript r_scripts/eda_and_preprocessing.R
R_LIBS_USER="$PWD/r_lib" Rscript r_scripts/predictive_model.R
```

Or run all stages using `scripts/run_all.sh` with PostgreSQL environment configured and `R_LIBS_USER="$PWD/r_lib"` exported.

## 3. Tableau Public on macOS (Apple silicon)

Verified installation: Tableau Public (Apple silicon), version 2026.3.1, at `/Applications/Tableau Public (Apple silicon).app`. Use only aggregate CSVs under `data/processed/`. Never connect `employee_abt.csv`, `salary_rank_local.csv`, or `attrition_predictions_local.csv`. The exact dashboard build sequence is in [tableau_setup_guide.md](tableau_setup_guide.md), and field formulas/validation are in `../bi_dashboard/calculations.md`.

Save the workbook locally as `bi_dashboard/dashboard_file.twbx`. Capture genuine screenshots in `assets/dashboard_previews/`. A Tableau Public upload is publicly visible; confirm source licensing and review all data sources, filters, tooltips and underlying data before publishing. Do not upload sensitive employee-level records. After publishing, verify the public link in a browser and update `bi_dashboard/bi_web_link.txt`.

## 4. GitHub and external showcase

The target remote is `https://github.com/Anshh1727/Big-Data-Analytics-Project`. Git identity is configured project-locally and global Git settings were not changed. No push is authorized yet. Check diff/status and ignored files, verify GitHub authentication under Anshh1727, then request explicit approval before any push. LinkedIn posting/tagging and resume integration remain user actions; drafts are provided in `showcase/`.
