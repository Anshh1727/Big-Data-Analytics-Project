#!/bin/sh
set -eu
PROJECT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT="$PROJECT_ROOT/data/processed"
DB_NAME=${PGDATABASE:-hr_analytics_db}
PSQL_BIN=${PSQL_BIN:-psql}
mkdir -p "$OUT"
"$PSQL_BIN" -X -v ON_ERROR_STOP=1 -d "$DB_NAME" <<SQL
\\copy (SELECT * FROM hr_analytics.v_employee_abt) TO '$OUT/employee_abt.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\\copy (SELECT * FROM hr_analytics.v_source_quality) TO '$OUT/source_quality.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\\copy (SELECT * FROM hr_analytics.v_source_missingness) TO '$OUT/source_missingness.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\\copy (SELECT * FROM hr_analytics.v_workforce_overview) TO '$OUT/workforce_overview.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\\copy (SELECT * FROM hr_analytics.v_job_role_overview) TO '$OUT/job_role_overview.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\\copy (SELECT * FROM hr_analytics.v_hiring_patterns) TO '$OUT/hiring_patterns.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\\copy (SELECT * FROM hr_analytics.v_attrition_by_tenure) TO '$OUT/attrition_by_tenure.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\\copy (SELECT * FROM hr_analytics.v_attrition_by_satisfaction) TO '$OUT/attrition_by_satisfaction.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\\copy (SELECT * FROM hr_analytics.v_attrition_by_workload) TO '$OUT/attrition_by_workload.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\\copy (SELECT * FROM hr_analytics.v_attrition_by_development) TO '$OUT/attrition_by_development.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\\copy (SELECT * FROM hr_analytics.v_performance_department) TO '$OUT/performance_department.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\\copy (SELECT * FROM hr_analytics.v_performance_by_role) TO '$OUT/performance_by_role.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\\copy (SELECT * FROM hr_analytics.v_performance_workforce_patterns) TO '$OUT/performance_workforce_patterns.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\\copy (SELECT * FROM hr_analytics.v_compensation_by_role_gender) TO '$OUT/compensation_by_role_gender.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\\copy (SELECT * FROM hr_analytics.v_compensation_by_tenure) TO '$OUT/compensation_by_tenure.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\\copy (SELECT * FROM hr_analytics.v_compensation_by_education_performance) TO '$OUT/compensation_by_education_performance.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\\copy (SELECT * FROM hr_analytics.v_salary_rank_local) TO '$OUT/salary_rank_local.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\\copy (SELECT * FROM hr_analytics.v_hr_dashboard_department) TO '$OUT/hr_dashboard_department.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\\copy (SELECT * FROM hr_analytics.v_attrition_by_salary_quartile) TO '$OUT/attrition_by_salary_quartile.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\\copy (SELECT * FROM hr_analytics.v_attrition_by_remote_frequency) TO '$OUT/attrition_by_remote_frequency.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\\copy (SELECT * FROM hr_analytics.v_attrition_by_training) TO '$OUT/attrition_by_training.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\\copy (SELECT * FROM hr_analytics.v_satisfaction_by_workstyle) TO '$OUT/satisfaction_by_workstyle.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\\copy (SELECT * FROM hr_analytics.v_compensation_by_department) TO '$OUT/compensation_by_department.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\\copy (SELECT * FROM hr_analytics.v_compensation_by_job_role) TO '$OUT/compensation_by_job_role.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\\copy (SELECT * FROM hr_analytics.v_compensation_by_gender) TO '$OUT/compensation_by_gender.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\\copy (SELECT * FROM hr_analytics.v_attrition_overall) TO '$OUT/attrition_overall.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\\copy (SELECT * FROM hr_analytics.v_workforce_age_band) TO '$OUT/workforce_age_band.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\\copy (SELECT * FROM hr_analytics.v_demographic_distribution) TO '$OUT/demographic_distribution.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\\copy (SELECT * FROM hr_analytics.v_promotions_by_tenure) TO '$OUT/promotions_by_tenure.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\\copy (SELECT * FROM hr_analytics.v_performance_by_training_band) TO '$OUT/performance_by_training_band.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
SQL
printf 'HR analysis exports written to %s\n' "$OUT"
