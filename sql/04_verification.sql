SET search_path TO hr_analytics, public;
\pset format aligned
\pset null '(null)'
SELECT check_name,check_value FROM v_source_quality ORDER BY check_name;
SELECT source_column,missing_rows FROM v_source_missingness ORDER BY source_column;
SELECT 'clean_employee_rows' AS check_name,COUNT(*)::bigint AS check_value FROM clean_employee_stage WHERE row_n=1;
SELECT 'employees_loaded' AS check_name,COUNT(*)::bigint AS check_value FROM employees;
SELECT 'unique_employee_ids' AS check_name,COUNT(DISTINCT employee_id)::bigint AS check_value FROM employees;
SELECT 'missing_workforce_metrics' AS check_name,COUNT(*)::bigint AS check_value
FROM employees e LEFT JOIN employee_workforce_metrics w USING(employee_id) WHERE w.employee_id IS NULL;
SELECT 'missing_performance_rows' AS check_name,COUNT(*)::bigint AS check_value
FROM employees e LEFT JOIN employee_performance p USING(employee_id) WHERE p.employee_id IS NULL;
SELECT 'missing_compensation_rows' AS check_name,COUNT(*)::bigint AS check_value
FROM employees e LEFT JOIN employee_compensation c USING(employee_id) WHERE c.employee_id IS NULL;
SELECT 'ABT_row_reconciliation' AS check_name,
       (SELECT COUNT(*) FROM employees)-(SELECT COUNT(*) FROM v_employee_abt) AS check_value;
SELECT 'duplicate_ABT_employees' AS check_name,COUNT(*)::bigint AS check_value
FROM (SELECT employee_id FROM v_employee_abt GROUP BY employee_id HAVING COUNT(*)>1) d;
SELECT 'resignation_count_reconciliation' AS check_name,
       (SELECT COUNT(*) FROM employees WHERE resigned)-(SELECT COUNT(*) FROM v_employee_abt WHERE resigned) AS check_value;
SELECT 'salary_total_reconciliation' AS check_name,
       (SELECT COALESCE(SUM(monthly_salary),0) FROM employee_compensation)
       -(SELECT COALESCE(SUM(monthly_salary),0) FROM v_employee_abt) AS check_value;
SELECT 'department_employee_count_reconciliation' AS check_name,
       (SELECT COUNT(*) FROM employees)-(SELECT COALESCE(SUM(employee_count),0) FROM v_hr_dashboard_department) AS check_value;
