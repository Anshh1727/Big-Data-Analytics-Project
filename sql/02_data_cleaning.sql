SET search_path TO hr_analytics, public;

-- Source-level quality audit. It retains missingness, duplicate keys, parse failures,
-- and out-of-range values as explicit checks instead of silently repairing them.
CREATE OR REPLACE VIEW v_source_quality AS
WITH parsed AS (
 SELECT *,
   CASE WHEN BTRIM(employee_id) ~ '^[0-9]+$' THEN CAST(BTRIM(employee_id) AS bigint) END AS employee_id_n,
   CASE WHEN BTRIM(age) ~ '^[0-9]+$' THEN CAST(BTRIM(age) AS integer) END AS age_n,
   CASE WHEN BTRIM(years_at_company) ~ '^[0-9]+([.][0-9]+)?$' THEN CAST(BTRIM(years_at_company) AS numeric) END AS tenure_n,
   CASE WHEN BTRIM(performance_score) ~ '^[0-9]+([.][0-9]+)?$' THEN CAST(BTRIM(performance_score) AS numeric) END AS performance_n,
   CASE WHEN BTRIM(monthly_salary) ~ '^[0-9]+([.][0-9]+)?$' THEN CAST(BTRIM(monthly_salary) AS numeric) END AS salary_n,
   CASE WHEN BTRIM(work_hours_per_week) ~ '^[0-9]+([.][0-9]+)?$' THEN CAST(BTRIM(work_hours_per_week) AS numeric) END AS work_hours_n,
   CASE WHEN BTRIM(overtime_hours) ~ '^[0-9]+([.][0-9]+)?$' THEN CAST(BTRIM(overtime_hours) AS numeric) END AS overtime_n,
   CASE WHEN BTRIM(remote_work_frequency) ~ '^[0-9]+([.][0-9]+)?$' THEN CAST(BTRIM(remote_work_frequency) AS numeric) END AS remote_n,
   CASE WHEN BTRIM(employee_satisfaction_score) ~ '^[0-9]+([.][0-9]+)?$' THEN CAST(BTRIM(employee_satisfaction_score) AS numeric) END AS satisfaction_n,
   CASE WHEN LOWER(BTRIM(resigned)) IN ('true','t','yes','y','1') THEN TRUE
        WHEN LOWER(BTRIM(resigned)) IN ('false','f','no','n','0') THEN FALSE END AS resigned_b,
   CASE WHEN BTRIM(hire_date) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}([.][0-9]+)?$' THEN CAST(BTRIM(hire_date) AS timestamp) END AS hire_date_ts
 FROM raw_hr_employees
)
SELECT 'source_rows' AS check_name, COUNT(*)::bigint AS check_value FROM raw_hr_employees
UNION ALL SELECT 'distinct_employee_ids', COUNT(DISTINCT employee_id_n) FROM parsed
UNION ALL SELECT 'duplicate_employee_id_rows', COUNT(*)-COUNT(DISTINCT employee_id_n) FROM parsed
UNION ALL SELECT 'missing_employee_id', COUNT(*) FILTER (WHERE NULLIF(BTRIM(employee_id),'') IS NULL) FROM parsed
UNION ALL SELECT 'missing_department', COUNT(*) FILTER (WHERE NULLIF(BTRIM(department),'') IS NULL) FROM parsed
UNION ALL SELECT 'missing_gender', COUNT(*) FILTER (WHERE NULLIF(BTRIM(gender),'') IS NULL) FROM parsed
UNION ALL SELECT 'missing_job_title', COUNT(*) FILTER (WHERE NULLIF(BTRIM(job_title),'') IS NULL) FROM parsed
UNION ALL SELECT 'missing_hire_date', COUNT(*) FILTER (WHERE NULLIF(BTRIM(hire_date),'') IS NULL) FROM parsed
UNION ALL SELECT 'invalid_hire_date', COUNT(*) FILTER (WHERE NULLIF(BTRIM(hire_date),'') IS NOT NULL AND hire_date_ts IS NULL) FROM parsed
UNION ALL SELECT 'invalid_resigned_value', COUNT(*) FILTER (WHERE resigned_b IS NULL) FROM parsed
UNION ALL SELECT 'invalid_age_or_out_of_range', COUNT(*) FILTER (WHERE age_n IS NULL OR age_n NOT BETWEEN 16 AND 100) FROM parsed
UNION ALL SELECT 'invalid_salary_or_negative', COUNT(*) FILTER (WHERE salary_n IS NULL OR salary_n < 0) FROM parsed
UNION ALL SELECT 'invalid_satisfaction_range', COUNT(*) FILTER (WHERE satisfaction_n IS NULL OR satisfaction_n NOT BETWEEN 0 AND 5) FROM parsed
UNION ALL SELECT 'invalid_remote_frequency_range', COUNT(*) FILTER (WHERE remote_n IS NULL OR remote_n NOT BETWEEN 0 AND 100) FROM parsed;

CREATE OR REPLACE VIEW v_source_missingness AS
SELECT 'Employee_ID' AS source_column,COUNT(*) FILTER (WHERE NULLIF(BTRIM(employee_id),'') IS NULL) AS missing_rows FROM raw_hr_employees
UNION ALL SELECT 'Department',COUNT(*) FILTER (WHERE NULLIF(BTRIM(department),'') IS NULL) FROM raw_hr_employees
UNION ALL SELECT 'Gender',COUNT(*) FILTER (WHERE NULLIF(BTRIM(gender),'') IS NULL) FROM raw_hr_employees
UNION ALL SELECT 'Age',COUNT(*) FILTER (WHERE NULLIF(BTRIM(age),'') IS NULL) FROM raw_hr_employees
UNION ALL SELECT 'Job_Title',COUNT(*) FILTER (WHERE NULLIF(BTRIM(job_title),'') IS NULL) FROM raw_hr_employees
UNION ALL SELECT 'Hire_Date',COUNT(*) FILTER (WHERE NULLIF(BTRIM(hire_date),'') IS NULL) FROM raw_hr_employees
UNION ALL SELECT 'Years_At_Company',COUNT(*) FILTER (WHERE NULLIF(BTRIM(years_at_company),'') IS NULL) FROM raw_hr_employees
UNION ALL SELECT 'Education_Level',COUNT(*) FILTER (WHERE NULLIF(BTRIM(education_level),'') IS NULL) FROM raw_hr_employees
UNION ALL SELECT 'Performance_Score',COUNT(*) FILTER (WHERE NULLIF(BTRIM(performance_score),'') IS NULL) FROM raw_hr_employees
UNION ALL SELECT 'Monthly_Salary',COUNT(*) FILTER (WHERE NULLIF(BTRIM(monthly_salary),'') IS NULL) FROM raw_hr_employees
UNION ALL SELECT 'Work_Hours_Per_Week',COUNT(*) FILTER (WHERE NULLIF(BTRIM(work_hours_per_week),'') IS NULL) FROM raw_hr_employees
UNION ALL SELECT 'Projects_Handled',COUNT(*) FILTER (WHERE NULLIF(BTRIM(projects_handled),'') IS NULL) FROM raw_hr_employees
UNION ALL SELECT 'Overtime_Hours',COUNT(*) FILTER (WHERE NULLIF(BTRIM(overtime_hours),'') IS NULL) FROM raw_hr_employees
UNION ALL SELECT 'Sick_Days',COUNT(*) FILTER (WHERE NULLIF(BTRIM(sick_days),'') IS NULL) FROM raw_hr_employees
UNION ALL SELECT 'Remote_Work_Frequency',COUNT(*) FILTER (WHERE NULLIF(BTRIM(remote_work_frequency),'') IS NULL) FROM raw_hr_employees
UNION ALL SELECT 'Team_Size',COUNT(*) FILTER (WHERE NULLIF(BTRIM(team_size),'') IS NULL) FROM raw_hr_employees
UNION ALL SELECT 'Training_Hours',COUNT(*) FILTER (WHERE NULLIF(BTRIM(training_hours),'') IS NULL) FROM raw_hr_employees
UNION ALL SELECT 'Promotions',COUNT(*) FILTER (WHERE NULLIF(BTRIM(promotions),'') IS NULL) FROM raw_hr_employees
UNION ALL SELECT 'Employee_Satisfaction_Score',COUNT(*) FILTER (WHERE NULLIF(BTRIM(employee_satisfaction_score),'') IS NULL) FROM raw_hr_employees
UNION ALL SELECT 'Resigned',COUNT(*) FILTER (WHERE NULLIF(BTRIM(resigned),'') IS NULL) FROM raw_hr_employees;

DROP TABLE IF EXISTS clean_employee_stage;
CREATE TABLE clean_employee_stage AS
WITH parsed AS (
 SELECT *,
   CASE WHEN BTRIM(employee_id) ~ '^[0-9]+$' THEN CAST(BTRIM(employee_id) AS bigint) END AS employee_id_n,
   CASE WHEN BTRIM(age) ~ '^[0-9]+$' THEN CAST(BTRIM(age) AS integer) END AS age_n,
   CASE WHEN BTRIM(years_at_company) ~ '^[0-9]+([.][0-9]+)?$' THEN CAST(BTRIM(years_at_company) AS numeric(6,2)) END AS tenure_n,
   CASE WHEN BTRIM(performance_score) ~ '^[0-9]+([.][0-9]+)?$' THEN CAST(BTRIM(performance_score) AS numeric(5,2)) END AS performance_n,
   CASE WHEN BTRIM(monthly_salary) ~ '^[0-9]+([.][0-9]+)?$' THEN CAST(BTRIM(monthly_salary) AS numeric(14,2)) END AS salary_n,
   CASE WHEN BTRIM(work_hours_per_week) ~ '^[0-9]+([.][0-9]+)?$' THEN CAST(BTRIM(work_hours_per_week) AS numeric(7,2)) END AS work_hours_n,
   CASE WHEN BTRIM(projects_handled) ~ '^[0-9]+$' THEN CAST(BTRIM(projects_handled) AS integer) END AS projects_n,
   CASE WHEN BTRIM(overtime_hours) ~ '^[0-9]+([.][0-9]+)?$' THEN CAST(BTRIM(overtime_hours) AS numeric(7,2)) END AS overtime_n,
   CASE WHEN BTRIM(sick_days) ~ '^[0-9]+$' THEN CAST(BTRIM(sick_days) AS integer) END AS sick_days_n,
   CASE WHEN BTRIM(remote_work_frequency) ~ '^[0-9]+([.][0-9]+)?$' THEN CAST(BTRIM(remote_work_frequency) AS numeric(6,2)) END AS remote_n,
   CASE WHEN BTRIM(team_size) ~ '^[0-9]+$' THEN CAST(BTRIM(team_size) AS integer) END AS team_size_n,
   CASE WHEN BTRIM(training_hours) ~ '^[0-9]+([.][0-9]+)?$' THEN CAST(BTRIM(training_hours) AS numeric(7,2)) END AS training_n,
   CASE WHEN BTRIM(promotions) ~ '^[0-9]+$' THEN CAST(BTRIM(promotions) AS integer) END AS promotions_n,
   CASE WHEN BTRIM(employee_satisfaction_score) ~ '^[0-9]+([.][0-9]+)?$' THEN CAST(BTRIM(employee_satisfaction_score) AS numeric(5,2)) END AS satisfaction_n,
   CASE WHEN LOWER(BTRIM(resigned)) IN ('true','t','yes','y','1') THEN TRUE
        WHEN LOWER(BTRIM(resigned)) IN ('false','f','no','n','0') THEN FALSE END AS resigned_b,
   CASE WHEN BTRIM(hire_date) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}([.][0-9]+)?$' THEN CAST(BTRIM(hire_date) AS timestamp) END AS hire_date_ts,
   ROW_NUMBER() OVER (PARTITION BY CASE WHEN BTRIM(employee_id) ~ '^[0-9]+$' THEN CAST(BTRIM(employee_id) AS bigint) END
                      ORDER BY employee_id, department, job_title, hire_date) AS row_n
 FROM raw_hr_employees
)
SELECT employee_id_n AS employee_id,
       INITCAP(NULLIF(BTRIM(department),'')) AS department,
       INITCAP(NULLIF(BTRIM(gender),'')) AS gender,
       age_n AS age,
       NULLIF(BTRIM(job_title),'') AS job_title,
       hire_date_ts AS hire_date,
       tenure_n AS years_at_company,
       INITCAP(NULLIF(BTRIM(education_level),'')) AS education_level,
       performance_n AS performance_score, salary_n AS monthly_salary,
       work_hours_n AS work_hours_per_week, projects_n AS projects_handled,
       overtime_n AS overtime_hours, sick_days_n AS sick_days,
       remote_n AS remote_work_frequency, team_size_n AS team_size,
       training_n AS training_hours, promotions_n AS promotions,
       satisfaction_n AS employee_satisfaction_score, resigned_b AS resigned,
       row_n
FROM parsed;

-- Rebuild derived tables deterministically; raw import remains available for audit.
TRUNCATE employee_workforce_metrics, employee_performance, employee_compensation, employees, departments, job_roles RESTART IDENTITY CASCADE;
INSERT INTO departments(department_name)
SELECT DISTINCT department FROM clean_employee_stage WHERE row_n=1 AND department IS NOT NULL
ON CONFLICT (department_name) DO NOTHING;
INSERT INTO job_roles(job_title)
SELECT DISTINCT job_title FROM clean_employee_stage WHERE row_n=1 AND job_title IS NOT NULL
ON CONFLICT (job_title) DO NOTHING;

INSERT INTO employees(employee_id,department_id,job_role_id,gender,age,hire_date,years_at_company,education_level,resigned)
SELECT s.employee_id,d.department_id,j.job_role_id,s.gender,s.age,s.hire_date,s.years_at_company,s.education_level,s.resigned
FROM clean_employee_stage s
INNER JOIN departments d ON d.department_name=s.department
INNER JOIN job_roles j ON j.job_title=s.job_title
WHERE s.row_n=1 AND s.employee_id IS NOT NULL AND s.resigned IS NOT NULL
  AND s.age BETWEEN 16 AND 100 AND s.years_at_company >= 0
  AND s.monthly_salary >= 0 AND s.employee_satisfaction_score BETWEEN 0 AND 5
  AND s.remote_work_frequency BETWEEN 0 AND 100
  AND s.work_hours_per_week >= 0 AND s.projects_handled >= 0 AND s.overtime_hours >= 0
  AND s.sick_days >= 0 AND s.team_size >= 1 AND s.training_hours >= 0 AND s.promotions >= 0
  AND s.performance_score BETWEEN 0 AND 5 AND s.hire_date IS NOT NULL;

INSERT INTO employee_workforce_metrics
SELECT e.employee_id,s.work_hours_per_week,s.projects_handled,s.overtime_hours,s.sick_days,
       s.remote_work_frequency,s.team_size,s.training_hours,s.promotions,s.employee_satisfaction_score
FROM clean_employee_stage s INNER JOIN employees e USING(employee_id);
INSERT INTO employee_performance
SELECT e.employee_id,s.performance_score FROM clean_employee_stage s INNER JOIN employees e USING(employee_id);
INSERT INTO employee_compensation
SELECT e.employee_id,s.monthly_salary FROM clean_employee_stage s INNER JOIN employees e USING(employee_id);
