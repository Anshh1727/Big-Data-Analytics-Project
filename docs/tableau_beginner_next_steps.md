# Tableau: finish the two remaining dashboards

This guide assumes Tableau Public is open with the recovered `Book1` workbook. A Tableau Public connection error does not stop local editing. Do not click **Save to Tableau Public**, **Save to Tableau Public As**, or press Command+S in Tableau Public; these may start an online save. Publishing and GitHub pushing remain paused until you approve them.

## First: protect the workbook locally

The current checkpoint is `bi_dashboard/tableau_recovery_checkpoint.twbx`. It contains the recovered Dashboard 1 and its three worksheets. In Tableau choose **File > Export Packaged Workbook…**, select the project’s `bi_dashboard` folder, enter `dashboard_file.twbx`, then click **Save**. This produces the required local deliverable and keeps its CSV extracts together. If Tableau shows a replace confirmation, approve replacing only `dashboard_file.twbx`.

To add a worksheet, use the **New Worksheet** icon beside the tabs along the bottom, or **Worksheet > New Worksheet**. Rename each new worksheet by double-clicking its tab. To connect a CSV, select **Data > New Data Source > Text file**, press **Command+Shift+G**, paste the complete project path shown below, press **Return**, then click **Open**. On the Data Source page, click **Sheet 1** at the bottom to make a view. The workbook’s existing `attrition_overall` and `hr_dashboard_department` sources are already connected; use them where listed.

## Dashboard 2 — Attrition & Performance

Build these four worksheets. For each one, drag the first field to **Rows** and the second field to **Columns**. Use the **Show Me** panel to choose **Horizontal Bars** if Tableau does not select bars automatically. Drag `resignation_proportion` onto **Color** too if desired. Keep `employee_count` available on **Tooltip** so viewers see each denominator.

| Worksheet | CSV/source | Rows | Columns | Useful tooltip |
|---|---|---|---|---|
| Attrition by Tenure | `data/processed/attrition_by_tenure.csv` (already connected in the open session) | `tenure_band` | `resignation_proportion` | `employee_count`, `resigned_count` |
| Attrition by Workload | `data/processed/attrition_by_workload.csv` | `overtime_band` | `resignation_proportion` | `employee_count`, `resigned_count`, `mean_work_hours` |
| Resignation by Department | existing `hr_dashboard_department` source | `department_name` | `resignation_proportion` | `employee_count`, `resigned_count` |
| Performance by Department | `data/processed/performance_department.csv` | `department_name` | `mean_performance_score` | `employee_count`, `mean_training_hours` |

Create the dashboard by clicking the **New Dashboard** icon beside the bottom tabs, or **Dashboard > New Dashboard**. In the left **Size** pane, choose **Fixed Size** and set width `1366`, height `768`. In the left **Sheets** list, drag the four worksheets onto the canvas; put the two attrition charts across the top and department performance charts across the bottom. Rename the dashboard tab **Attrition & Performance**. Drag a **Text** object onto the bottom edge and enter: “Synthetic cross-sectional status patterns; not a forward turnover forecast. The retrospective attrition model did not outperform a no-skill baseline and must not be used for employee decisions.”

For the department chart, click its small dropdown on the dashboard and choose **Use as Filter**. Keep this filter scoped to department views. Do not imply it filters tenure/workload views unless you explicitly configure and verify a shared filter.

## Dashboard 3 — Compensation Equity

Build these three worksheets using the same **New Worksheet** and CSV connection steps above.

| Worksheet | CSV | Rows | Columns | Useful tooltip |
|---|---|---|---|---|
| Mean Salary by Department | `data/processed/compensation_by_department.csv` | `department_name` | `mean_monthly_salary` | `median_monthly_salary`, `employee_count` |
| Salary by Role and Gender | `data/processed/compensation_by_role_gender.csv` | `job_title` | `publishable_mean_salary` | `department_name`, `gender`, `employee_count` |
| Salary by Tenure | `data/processed/compensation_by_tenure.csv` | `tenure_band` | `mean_monthly_salary` | `median_monthly_salary`, `employee_count` |

Use horizontal bars and sort salary views descending by the salary measure. In **Salary by Role and Gender**, drag `gender` to **Color** and `department_name` to **Filters**. The supplied role/gender data already suppresses groups smaller than 30; keep the provided `publishable_mean_salary` field and do not reconnect employee-level data. Set the dashboard to fixed `1366 × 768`, drag in the three worksheets, name it **Compensation Equity**, and add this text: “Synthetic sample; not evidence of real-world pay equity. Salary units/currency context is unspecified. Group comparisons are descriptive and associational.”

## Final local save and check

Choose **File > Export Packaged Workbook…** and export to `bi_dashboard/dashboard_file.twbx`. Reopen that exact file from Finder to verify all three dashboard tabs render. Do not capture or claim a dashboard screenshot unless it is a genuine Tableau screenshot. For now, the public link remains unpublished and GitHub remains untouched. Tableau Public publishing requires a working connection to `public.tableau.com` and your explicit approval.
