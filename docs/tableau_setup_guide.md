# Tableau Public build guide: three interactive HR dashboards

Tableau Public is installed at `/Applications/Tableau Public (Apple silicon).app` (verified version 2026.3.1). Tableau Public workbooks and published visualizations are public. Connect only to the aggregate CSVs listed below. Do not use `employee_abt.csv`, `salary_rank_local.csv`, or `attrition_predictions_local.csv`; those contain employee-level information and remain local.

## Prepare the sources

Run SQL and R first. `data/processed/` is intentionally Git-ignored and regenerated locally. Use these aggregate exports:

- `workforce_overview.csv`, `hr_dashboard_department.csv`, `job_role_overview.csv`, `hiring_patterns.csv`, `workforce_age_band.csv`, `demographic_distribution.csv`
- `attrition_overall.csv`, `attrition_by_development.csv`, `attrition_by_dept` (from `hr_dashboard_department.csv`), `attrition_by_tenure.csv`, `attrition_by_satisfaction.csv`, `attrition_by_workload.csv`, `attrition_by_salary_quartile.csv`, `attrition_by_remote_frequency.csv`, `attrition_by_training.csv`
- `performance_department.csv`, `performance_by_role.csv`, `performance_workforce_patterns.csv`, `performance_by_training_band.csv`, `satisfaction_by_workstyle.csv`, `promotions_by_tenure.csv`
- `compensation_by_department.csv`, `compensation_by_job_role.csv`, `compensation_by_gender.csv`, `compensation_by_role_gender.csv`, `compensation_by_tenure.csv`, `compensation_by_education_performance.csv`
- R model summary aggregates: `attrition_model_metrics.csv`, `attrition_model_department_aggregate.csv`, `pay_equity_model_metrics.csv`, `pay_gap_female_vs_male.csv`, `pay_equity_adjusted_coefficients.csv`.

Each export is already at an aggregate grain, not a unified employee table. Use the single-row `attrition_overall.csv` for overall workforce KPIs and the department-grain `workforce_overview.csv` / `hr_dashboard_department.csv` for grouped views. Avoid joining multiple aggregate files because their grains differ. Use separate data sources per worksheet as needed. The full data-source manifest is `bi_dashboard/tableau_export_manifest.csv`.

## Exact Tableau interface actions

1. Open Tableau Public from **Applications**. On the Connect start page, under **To a File**, click **Text file**. In the macOS file chooser press **Command+Shift+G**, enter the full path to one aggregate CSV (for example, `.../Big-Data-Anshu/data/processed/attrition_overall.csv`), press **Return**, then click **Open**.
2. On the **Data Source** tab, verify the field headers and preview rows. Click **Sheet 1** at the bottom. Tableau's left **Data** pane lists dimensions (blue) and measures (green). Create a view by dragging the named fields from this guide to **Rows**, **Columns**, and **Marks**. Use the **Show Me** button if you want to switch a bar/line/text chart after selecting fields.
3. Rename a worksheet by double-clicking its sheet tab. Use the bottom **New Worksheet** icon to create another worksheet. When a worksheet needs a different aggregate CSV, select **Data > New Data Source > Text file** and repeat steps 1–2; the new worksheet can select its source from the top of the Data pane. Do not physically join these separate aggregate CSVs.
4. To make a page, choose **Dashboard > New Dashboard** from the macOS menu (or click the **New Dashboard** icon beside the sheet tabs). In the left **Size** control choose **Fixed Size**, set 1366 × 768. Drag the desired sheet tabs from the left **Sheets** list onto the canvas. Drag a **Text** object from the left **Objects** list onto the canvas for the caveat notes in this guide.
5. To add an interactive filter, open the worksheet menu on the dashboard (small dropdown on its upper-right edge), choose **Filters**, and select the field. On the filter card menu select **Apply to Worksheets > Selected Worksheets** and select only views that share the same compatible source/grain. For cross-filtering, choose the view's dropdown and **Use as Filter**; verify that unrelated-source KPIs do not change.
6. To save a local portable copy, choose **File > Export Packaged Workbook…**, browse to `bi_dashboard/`, and name it `dashboard_file.twbx`. This is the local export command in Tableau Public. **Do not use “Save to Tableau Public As…”** unless you have approved publishing. Reopen the saved workbook once to ensure the extracts are included and the dashboards still render.

## Dashboard 1 — Workforce Overview

1. Connect `attrition_overall.csv`; create one-row KPI sheets for `unique_employee_count`, `cross_sectional_resignation_proportion`, `average_satisfaction`, and `average_performance_score`. Format the proportion as a percentage and title it “Cross-sectional resigned share.”
2. Connect `hr_dashboard_department.csv`. Build horizontal bar views with `department_name` on Rows and `employee_count` or `resignation_proportion` on Columns. Add `resigned_count` and `employee_count` to tooltips. Sort by the selected measure.
3. Connect `hiring_patterns.csv`; make a hiring-year bar chart. If the source year/date in this sample is a generated distribution, label the chart as source-record composition, not actual recruitment trend.
4. Connect `workforce_age_band.csv` and `demographic_distribution.csv` for age band and workforce composition. Use suppression/neutral wording; don’t infer representativeness.
5. Create dashboard **Workforce Overview**, size 1366 × 768. Arrange KPI row, department chart, composition and hire-year views. Add a Department filter to department worksheets only; do not imply it filters KPIs from separate sources. Add a text note: “Synthetic, cross-sectional data. Not a real employer workforce.”

## Dashboard 2 — Attrition & Performance

1. Connect `attrition_overall.csv`; chart `active_records` and `resigned_records`, or show `cross_sectional_resignation_proportion`. Show `employee_records` and mark the measure as cross-sectional status share, not forward turnover forecast.
2. Connect `hr_dashboard_department.csv` for `resignation_proportion`, `resigned_count` and `employee_count` by `department_name`. Sort and show denominator.
3. Make separate worksheets from `attrition_by_tenure.csv`, `attrition_by_workload.csv`, `attrition_by_training.csv`, `attrition_by_satisfaction.csv`, `attrition_by_remote_frequency.csv`, and `attrition_by_salary_quartile.csv`. Choose a bar or line plot based on category order; show count in tooltip and resignation proportion on axis.
4. Connect `performance_department.csv`, `performance_by_role.csv`, `performance_by_training_band.csv`, `performance_workforce_patterns.csv` and `promotions_by_tenure.csv` for group means/distributions. Keep each at its own grain; use separate sources rather than relationships for this fixed aggregate view.
5. Add model summary KPI from `attrition_model_metrics.csv`: ROC-AUC 0.494, PR-AUC 0.097, prevalence 0.100, with annotation that thresholding yielded 0 specificity. Do not import individual predictions or rank people.
6. Assemble **Attrition & Performance** with filters limited to the applicable worksheets. Include text: “Retrospective synthetic classification; model failed to outperform a no-skill baseline. Do not use for employee decisions.”

## Dashboard 3 — Compensation Equity

1. Connect `compensation_by_department.csv` and `compensation_by_job_role.csv`. Build separate horizontal salary bars with `department_name` / `job_title`, `mean_monthly_salary`, `median_monthly_salary`, and `employee_count`. Salary unit/currency is unspecified; label “source salary units.”
2. Connect `compensation_by_gender.csv` and `compensation_by_role_gender.csv`. Plot `mean_monthly_salary` and `median_monthly_salary` with `employee_count`. The SQL role-gender extract suppresses comparison groups under 30; preserve the suppression and use `publishable_mean_salary` where relevant. Use no individual-level salary records.
3. Connect `compensation_by_tenure.csv` and `compensation_by_education_performance.csv` for salary summaries by these categories.
4. Add aggregate regression statistics from `pay_equity_model_metrics.csv` and `pay_gap_female_vs_male.csv`. Annotation: “Synthetic sample; not evidence of real-world pay equity. Regression is associational; unmeasured job level/currency context is unavailable.”
5. Assemble **Compensation Equity** with filters scoped to compatible sources. Avoid displaying gender-only comparisons without role/context and denominators.

## Suggested calculated fields

Use only where compatible with the source grain; avoid recalculating from aggregate averages as if they were employee-level records.

- Rate: `IF SUM([Employee Count]) = 0 THEN NULL ELSE SUM([Resigned Count]) / SUM([Employee Count]) END` (rename fields to match export schema).
- Mean compensation (aggregate): use the exported mean field directly. Do not average subgroup means to produce an overall mean; use the workforce-wide summary from the source metrics.
- Pay gap percent: `100 * ([Female Mean] - [Male Mean]) / [Male Mean]`, only when both groups have sufficient n and the male mean is nonzero.

Detailed Tableau syntax and validation contracts: `bi_dashboard/calculations.md`.

## Save, validate, and publish

1. Save workbook as `bi_dashboard/dashboard_file.twbx` (Tableau Packaged Workbook). Confirm it contains only approved aggregate extracts.
2. Validate every dashboard's totals against the CSV/SQL output; check filters, tooltips, category counts, axis units and null handling. Capture actual PNG screenshots in `assets/dashboard_previews/`.
3. Check Kaggle license/terms and Tableau Public visibility. Publishing makes the workbook and its included data public. If the source terms or privacy review are unclear, save and submit the local workbook without public publishing.
4. If publishing is approved and appropriate, use **File > Save to Tableau Public As**, sign in, inspect the published view, test interactions and record the real URL in `bi_dashboard/bi_web_link.txt`. Never fabricate a link or screenshot.
