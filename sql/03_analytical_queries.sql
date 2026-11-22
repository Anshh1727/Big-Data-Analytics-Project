SET search_path TO hr_analytics, public;

-- Employee ABT grain is exactly one source employee ID. Each child measure table
-- is one-to-one on employee_id; dimensions are one-row-per-category.
CREATE OR REPLACE VIEW v_employee_abt AS
SELECT e.employee_id,d.department_name,j.job_title,COALESCE(e.gender,'Unknown') AS gender,e.age,e.hire_date,
       e.years_at_company,COALESCE(e.education_level,'Unknown') AS education_level,e.resigned,
       p.performance_score,c.monthly_salary,
       w.work_hours_per_week,w.projects_handled,w.overtime_hours,w.sick_days,
       w.remote_work_frequency,w.team_size,w.training_hours,w.promotions,
       w.employee_satisfaction_score
FROM employees e
INNER JOIN departments d ON d.department_id=e.department_id
INNER JOIN job_roles j ON j.job_role_id=e.job_role_id
LEFT JOIN employee_workforce_metrics w ON w.employee_id=e.employee_id
LEFT JOIN employee_performance p ON p.employee_id=e.employee_id
LEFT JOIN employee_compensation c ON c.employee_id=e.employee_id;

CREATE OR REPLACE VIEW v_workforce_overview AS
SELECT department_name,COUNT(*) AS employee_count,
       COUNT(*) FILTER (WHERE NOT resigned) AS active_count,
       COUNT(*) FILTER (WHERE resigned) AS resigned_count,
       COUNT(*) FILTER (WHERE resigned)::numeric/NULLIF(COUNT(*),0) AS resignation_proportion,
       AVG(years_at_company)::numeric(8,2) AS mean_tenure_years,
       AVG(performance_score)::numeric(8,2) AS mean_performance_score,
       AVG(monthly_salary)::numeric(14,2) AS mean_monthly_salary,
       AVG(employee_satisfaction_score)::numeric(8,2) AS mean_satisfaction
FROM v_employee_abt GROUP BY department_name;

CREATE OR REPLACE VIEW v_job_role_overview AS
SELECT department_name,job_title,COUNT(*) AS employee_count,
       COUNT(*) FILTER (WHERE resigned) AS resigned_count,
       COUNT(*) FILTER (WHERE resigned)::numeric/NULLIF(COUNT(*),0) AS resignation_proportion,
       AVG(years_at_company)::numeric(8,2) AS mean_tenure_years,
       AVG(performance_score)::numeric(8,2) AS mean_performance_score,
       AVG(monthly_salary)::numeric(14,2) AS mean_monthly_salary,
       AVG(employee_satisfaction_score)::numeric(8,2) AS mean_satisfaction
FROM v_employee_abt GROUP BY department_name,job_title;

CREATE OR REPLACE VIEW v_hiring_patterns AS
SELECT DATE_TRUNC('month',hire_date)::date AS hire_month,
       COUNT(*) AS employee_records,
       COUNT(*) FILTER (WHERE resigned) AS resigned_records
FROM employees WHERE hire_date IS NOT NULL
GROUP BY DATE_TRUNC('month',hire_date)::date
ORDER BY hire_month;
-- Hire-date counts describe the synthetic cross-sectional sample, not historical headcount.

CREATE OR REPLACE VIEW v_attrition_by_tenure AS
WITH banded AS (
 SELECT CASE WHEN years_at_company < 1 THEN '<1 year'
             WHEN years_at_company < 3 THEN '1-2 years'
             WHEN years_at_company < 6 THEN '3-5 years'
             WHEN years_at_company < 10 THEN '6-9 years' ELSE '10+ years' END AS tenure_band,
        resigned FROM v_employee_abt
)
SELECT tenure_band,COUNT(*) AS employee_count,
       COUNT(*) FILTER (WHERE resigned) AS resigned_count,
       COUNT(*) FILTER (WHERE resigned)::numeric/NULLIF(COUNT(*),0) AS resignation_proportion
FROM banded GROUP BY tenure_band;

CREATE OR REPLACE VIEW v_attrition_by_satisfaction AS
SELECT employee_satisfaction_score,COUNT(*) AS employee_count,
       COUNT(*) FILTER (WHERE resigned) AS resigned_count,
       COUNT(*) FILTER (WHERE resigned)::numeric/NULLIF(COUNT(*),0) AS resignation_proportion
FROM v_employee_abt GROUP BY employee_satisfaction_score;

CREATE OR REPLACE VIEW v_attrition_by_workload AS
SELECT CASE WHEN overtime_hours=0 THEN '0 hours'
            WHEN overtime_hours<=5 THEN '1-5 hours'
            WHEN overtime_hours<=10 THEN '6-10 hours' ELSE '11+ hours' END AS overtime_band,
       COUNT(*) AS employee_count,
       COUNT(*) FILTER (WHERE resigned) AS resigned_count,
       COUNT(*) FILTER (WHERE resigned)::numeric/NULLIF(COUNT(*),0) AS resignation_proportion,
       AVG(work_hours_per_week)::numeric(8,2) AS mean_work_hours,
       AVG(projects_handled)::numeric(8,2) AS mean_projects,
       AVG(performance_score)::numeric(8,2) AS mean_performance
FROM v_employee_abt GROUP BY 1;

CREATE OR REPLACE VIEW v_attrition_by_development AS
SELECT CASE WHEN promotions=0 THEN '0 promotions'
            WHEN promotions=1 THEN '1 promotion' ELSE '2+ promotions' END AS promotion_group,
       COUNT(*) AS employee_count,
       COUNT(*) FILTER (WHERE resigned) AS resigned_count,
       COUNT(*) FILTER (WHERE resigned)::numeric/NULLIF(COUNT(*),0) AS resignation_proportion,
       AVG(training_hours)::numeric(8,2) AS mean_training_hours,
       AVG(employee_satisfaction_score)::numeric(8,2) AS mean_satisfaction
FROM v_employee_abt GROUP BY 1;

CREATE OR REPLACE VIEW v_performance_department AS
SELECT department_name,COUNT(*) AS employee_count,
       AVG(performance_score)::numeric(8,3) AS mean_performance_score,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY performance_score)::numeric(8,3) AS median_performance_score,
       AVG(training_hours)::numeric(8,2) AS mean_training_hours,
       AVG(work_hours_per_week)::numeric(8,2) AS mean_work_hours,
       AVG(projects_handled)::numeric(8,2) AS mean_projects,
       RANK() OVER (ORDER BY AVG(performance_score) DESC) AS department_performance_rank,
       DENSE_RANK() OVER (ORDER BY AVG(training_hours) DESC) AS training_hours_rank
FROM v_employee_abt GROUP BY department_name;

CREATE OR REPLACE VIEW v_performance_by_role AS
SELECT department_name,job_title,COUNT(*) AS employee_count,
       AVG(performance_score)::numeric(8,3) AS mean_performance_score,
       AVG(training_hours)::numeric(8,2) AS mean_training_hours,
       AVG(work_hours_per_week)::numeric(8,2) AS mean_work_hours,
       AVG(projects_handled)::numeric(8,2) AS mean_projects,
       AVG(years_at_company)::numeric(8,2) AS mean_tenure_years,
       AVG(employee_satisfaction_score)::numeric(8,2) AS mean_satisfaction,
       RANK() OVER (PARTITION BY department_name ORDER BY AVG(performance_score) DESC) AS role_performance_rank
FROM v_employee_abt GROUP BY department_name,job_title;

CREATE OR REPLACE VIEW v_performance_workforce_patterns AS
SELECT department_name,job_title,
       COUNT(*) AS employee_count,
       AVG(performance_score)::numeric(8,3) AS mean_performance_score,
       AVG(training_hours)::numeric(8,2) AS mean_training_hours,
       AVG(promotions)::numeric(8,2) AS mean_promotions,
       AVG(work_hours_per_week)::numeric(8,2) AS mean_work_hours,
       AVG(overtime_hours)::numeric(8,2) AS mean_overtime_hours,
       AVG(projects_handled)::numeric(8,2) AS mean_projects_handled,
       AVG(employee_satisfaction_score)::numeric(8,2) AS mean_satisfaction
FROM v_employee_abt GROUP BY department_name,job_title HAVING COUNT(*)>=30;

CREATE OR REPLACE VIEW v_compensation_by_role_gender AS
SELECT department_name,job_title,gender,COUNT(*) AS employee_count,
       AVG(monthly_salary)::numeric(14,2) AS mean_monthly_salary,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY monthly_salary)::numeric(14,2) AS median_monthly_salary,
       PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY monthly_salary)::numeric(14,2) AS p25_salary,
       PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY monthly_salary)::numeric(14,2) AS p75_salary,
       CASE WHEN COUNT(*)>=30 THEN AVG(monthly_salary)::numeric(14,2) END AS publishable_mean_salary
FROM v_employee_abt WHERE monthly_salary IS NOT NULL
GROUP BY department_name,job_title,gender
HAVING COUNT(*)>=30;

CREATE OR REPLACE VIEW v_compensation_by_tenure AS
SELECT CASE WHEN years_at_company<1 THEN '<1 year'
            WHEN years_at_company<3 THEN '1-2 years'
            WHEN years_at_company<6 THEN '3-5 years'
            WHEN years_at_company<10 THEN '6-9 years' ELSE '10+ years' END AS tenure_band,
       COUNT(*) AS employee_count,AVG(monthly_salary)::numeric(14,2) AS mean_monthly_salary,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY monthly_salary)::numeric(14,2) AS median_monthly_salary
FROM v_employee_abt GROUP BY 1;

CREATE OR REPLACE VIEW v_compensation_by_education_performance AS
SELECT education_level,performance_score,COUNT(*) AS employee_count,
       AVG(monthly_salary)::numeric(14,2) AS mean_monthly_salary,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY monthly_salary)::numeric(14,2) AS median_monthly_salary
FROM v_employee_abt GROUP BY education_level,performance_score HAVING COUNT(*)>=30;

-- Within-role salary percentiles and ranks for local analysis. Do not expose employee rows publicly.
CREATE OR REPLACE VIEW v_salary_rank_local AS
SELECT employee_id,department_name,job_title,gender,monthly_salary,
       RANK() OVER (PARTITION BY job_title ORDER BY monthly_salary DESC) AS role_salary_rank,
       DENSE_RANK() OVER (PARTITION BY department_name ORDER BY monthly_salary DESC) AS department_salary_rank,
       ROW_NUMBER() OVER (PARTITION BY job_title ORDER BY monthly_salary DESC,employee_id) AS role_salary_row_number,
       PERCENT_RANK() OVER (PARTITION BY job_title ORDER BY monthly_salary) AS role_salary_percentile,
       AVG(monthly_salary) OVER (PARTITION BY department_name,job_title) AS role_department_mean_salary
FROM v_employee_abt WHERE monthly_salary IS NOT NULL;

CREATE OR REPLACE VIEW v_hr_dashboard_department AS
SELECT department_name,COUNT(*) AS employee_count,
       COUNT(*) FILTER (WHERE NOT resigned) AS active_count,
       COUNT(*) FILTER (WHERE resigned) AS resigned_count,
       COUNT(*) FILTER (WHERE resigned)::numeric/NULLIF(COUNT(*),0) AS resignation_proportion,
       AVG(monthly_salary)::numeric(14,2) AS mean_salary,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY monthly_salary)::numeric(14,2) AS median_salary,
       AVG(performance_score)::numeric(8,2) AS mean_performance,
       AVG(years_at_company)::numeric(8,2) AS mean_tenure,
       AVG(employee_satisfaction_score)::numeric(8,2) AS mean_satisfaction,
       AVG(training_hours)::numeric(8,2) AS mean_training_hours
FROM v_employee_abt GROUP BY department_name;

CREATE OR REPLACE VIEW v_attrition_by_salary_quartile AS
WITH ranked AS (
 SELECT *,NTILE(4) OVER (ORDER BY monthly_salary) AS salary_quartile
 FROM v_employee_abt WHERE monthly_salary IS NOT NULL
)
SELECT salary_quartile,COUNT(*) AS employee_count,
       COUNT(*) FILTER (WHERE resigned) AS resigned_count,
       COUNT(*) FILTER (WHERE resigned)::numeric/NULLIF(COUNT(*),0) AS resignation_proportion,
       MIN(monthly_salary)::numeric(14,2) AS min_salary,
       MAX(monthly_salary)::numeric(14,2) AS max_salary,
       AVG(monthly_salary)::numeric(14,2) AS mean_salary
FROM ranked GROUP BY salary_quartile;

CREATE OR REPLACE VIEW v_attrition_by_remote_frequency AS
SELECT remote_work_frequency,COUNT(*) AS employee_count,
       COUNT(*) FILTER (WHERE resigned) AS resigned_count,
       COUNT(*) FILTER (WHERE resigned)::numeric/NULLIF(COUNT(*),0) AS resignation_proportion,
       AVG(employee_satisfaction_score)::numeric(8,2) AS mean_satisfaction,
       AVG(performance_score)::numeric(8,2) AS mean_performance
FROM v_employee_abt GROUP BY remote_work_frequency;

CREATE OR REPLACE VIEW v_attrition_by_training AS
SELECT CASE WHEN training_hours<10 THEN '<10 hours'
            WHEN training_hours<25 THEN '10-24 hours'
            WHEN training_hours<50 THEN '25-49 hours' ELSE '50+ hours' END AS training_band,
       COUNT(*) AS employee_count,
       COUNT(*) FILTER (WHERE resigned) AS resigned_count,
       COUNT(*) FILTER (WHERE resigned)::numeric/NULLIF(COUNT(*),0) AS resignation_proportion,
       AVG(performance_score)::numeric(8,2) AS mean_performance,
       AVG(employee_satisfaction_score)::numeric(8,2) AS mean_satisfaction
FROM v_employee_abt GROUP BY 1;

CREATE OR REPLACE VIEW v_satisfaction_by_workstyle AS
SELECT remote_work_frequency,
       CASE WHEN work_hours_per_week<35 THEN '<35 hours'
            WHEN work_hours_per_week<=40 THEN '35-40 hours'
            WHEN work_hours_per_week<=45 THEN '41-45 hours' ELSE '46+ hours' END AS work_hours_band,
       COUNT(*) AS employee_count,
       AVG(employee_satisfaction_score)::numeric(8,2) AS mean_satisfaction,
       AVG(overtime_hours)::numeric(8,2) AS mean_overtime_hours,
       AVG(performance_score)::numeric(8,2) AS mean_performance,
       COUNT(*) FILTER (WHERE resigned)::numeric/NULLIF(COUNT(*),0) AS resignation_proportion
FROM v_employee_abt GROUP BY remote_work_frequency,2;

CREATE OR REPLACE VIEW v_compensation_by_department AS
SELECT department_name,COUNT(*) AS employee_count,
       AVG(monthly_salary)::numeric(14,2) AS mean_monthly_salary,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY monthly_salary)::numeric(14,2) AS median_monthly_salary,
       PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY monthly_salary)::numeric(14,2) AS p25_salary,
       PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY monthly_salary)::numeric(14,2) AS p75_salary
FROM v_employee_abt WHERE monthly_salary IS NOT NULL GROUP BY department_name;

CREATE OR REPLACE VIEW v_compensation_by_job_role AS
SELECT department_name,job_title,COUNT(*) AS employee_count,
       AVG(monthly_salary)::numeric(14,2) AS mean_monthly_salary,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY monthly_salary)::numeric(14,2) AS median_monthly_salary,
       PERCENTILE_CONT(0.1) WITHIN GROUP (ORDER BY monthly_salary)::numeric(14,2) AS p10_salary,
       PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY monthly_salary)::numeric(14,2) AS p90_salary
FROM v_employee_abt WHERE monthly_salary IS NOT NULL GROUP BY department_name,job_title HAVING COUNT(*)>=30;

CREATE OR REPLACE VIEW v_compensation_by_gender AS
SELECT gender,COUNT(*) AS employee_count,
       AVG(monthly_salary)::numeric(14,2) AS mean_monthly_salary,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY monthly_salary)::numeric(14,2) AS median_monthly_salary
FROM v_employee_abt WHERE monthly_salary IS NOT NULL
GROUP BY gender HAVING COUNT(*)>=30;

CREATE OR REPLACE VIEW v_attrition_overall AS
SELECT COUNT(*) AS employee_records,
       COUNT(DISTINCT employee_id) AS unique_employee_count,
       COUNT(*) FILTER (WHERE NOT resigned) AS active_records,
       COUNT(*) FILTER (WHERE resigned) AS resigned_records,
       COUNT(*) FILTER (WHERE resigned)::numeric/NULLIF(COUNT(*),0) AS cross_sectional_resignation_proportion,
       AVG(years_at_company)::numeric(8,2) AS average_tenure_years,
       AVG(monthly_salary)::numeric(14,2) AS average_monthly_salary,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY monthly_salary)::numeric(14,2) AS median_monthly_salary,
       AVG(performance_score)::numeric(8,2) AS average_performance_score,
       AVG(employee_satisfaction_score)::numeric(8,2) AS average_satisfaction
FROM v_employee_abt;

CREATE OR REPLACE VIEW v_department_performance_ranked AS
SELECT department_name,employee_count,mean_performance_score,
       RANK() OVER (ORDER BY mean_performance_score DESC) AS performance_rank,
       DENSE_RANK() OVER (ORDER BY mean_training_hours DESC) AS training_rank
FROM v_performance_department;

CREATE OR REPLACE VIEW v_workforce_age_band AS
SELECT CASE WHEN age<25 THEN '<25'
            WHEN age<35 THEN '25-34'
            WHEN age<45 THEN '35-44'
            WHEN age<55 THEN '45-54' ELSE '55+' END AS age_band,
       COUNT(*) AS employee_count,
       COUNT(*) FILTER (WHERE resigned) AS resigned_count,
       COUNT(*) FILTER (WHERE resigned)::numeric/NULLIF(COUNT(*),0) AS resignation_proportion
FROM v_employee_abt GROUP BY 1;

CREATE OR REPLACE VIEW v_demographic_distribution AS
SELECT 'Gender'::text AS dimension,gender AS category,COUNT(*) AS employee_count,
       COUNT(*) FILTER (WHERE resigned) AS resigned_count,
       COUNT(*) FILTER (WHERE resigned)::numeric/NULLIF(COUNT(*),0) AS resignation_proportion
FROM v_employee_abt GROUP BY gender HAVING COUNT(*)>=30
UNION ALL SELECT 'Education',education_level,COUNT(*),COUNT(*) FILTER(WHERE resigned),
       COUNT(*) FILTER(WHERE resigned)::numeric/NULLIF(COUNT(*),0)
FROM v_employee_abt GROUP BY education_level HAVING COUNT(*)>=30
UNION ALL SELECT 'Age band',age_band,employee_count,resigned_count,resignation_proportion
FROM v_workforce_age_band WHERE employee_count>=30;

CREATE OR REPLACE VIEW v_promotions_by_tenure AS
SELECT CASE WHEN years_at_company<1 THEN '<1 year'
            WHEN years_at_company<3 THEN '1-2 years'
            WHEN years_at_company<6 THEN '3-5 years'
            WHEN years_at_company<10 THEN '6-9 years' ELSE '10+ years' END AS tenure_band,
       COUNT(*) AS employee_count,AVG(promotions)::numeric(8,2) AS mean_promotions,
       AVG(employee_satisfaction_score)::numeric(8,2) AS mean_satisfaction,
       COUNT(*) FILTER (WHERE resigned)::numeric/NULLIF(COUNT(*),0) AS resignation_proportion
FROM v_employee_abt GROUP BY 1;

CREATE OR REPLACE VIEW v_performance_by_training_band AS
SELECT CASE WHEN training_hours<10 THEN '<10 hours'
            WHEN training_hours<25 THEN '10-24 hours'
            WHEN training_hours<50 THEN '25-49 hours' ELSE '50+ hours' END AS training_band,
       COUNT(*) AS employee_count,AVG(performance_score)::numeric(8,3) AS mean_performance_score,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY performance_score)::numeric(8,3) AS median_performance_score,
       AVG(employee_satisfaction_score)::numeric(8,2) AS mean_satisfaction
FROM v_employee_abt GROUP BY 1;
