# Data dictionary — Employee Performance and Productivity Data

## Provenance and eligibility

- **Dataset:** Employee Performance and Productivity Data (extended CSV)
- **Publisher/source:** mexwell, [Kaggle dataset](https://www.kaggle.com/datasets/mexwell/employee-performance-and-productivity-data)
- **Local file:** `data/raw/Extended_Employee_Performance_and_Productivity_Data.csv`
- **Observed file size:** 11,243,502 bytes; SHA-256 `2b1e07caf58e7678a780d428c1a8893a95d9c4a556134fd8e7368db5ed596cdb`
- **Local verified shape:** 100,000 data rows × 20 columns; 100,000 distinct Employee_ID values; 0 blank fields; 0 malformed CSV rows.
- **Access date:** 22 November 2026 (user-provided Kaggle download).
- **Synthetic-data status:** Synthetic, not observations of real employees or a real employer. The student confirmed on 22 November 2026 that the BA4301 instructor approved this dataset as an exception to the assignment’s real-world-data requirement. The source and every result remain labelled synthetic; retain written faculty approval if the instructor requires evidence.
- **License:** Kaggle dataset metadata currently lists **CC0: Public Domain** (verified through the Kaggle dataset metadata API on 22 November 2026). The source CSV is excluded from Git; the Tableau package contains only aggregate extracts, with no employee-level rows.
- **Source period:** Individual hire dates are present, but the file has no as-of date, separation date, or event chronology. Do not interpret hire-date counts as historical headcount or `Resigned` as a period turnover rate.
- **Salary currency/scale:** Not specified by the source metadata. Outputs say “dataset salary units,” not USD or any other currency.

## Observed columns and working types

The CSV was inspected directly and loaded through PostgreSQL text staging. PostgreSQL parsed each field into the following typed schema. No missing or invalid records were found in the 100,000-row file under the documented checks.

| Source field | PostgreSQL field | Type | Meaning / units | Modeling or cleaning note |
|---|---|---|---|---|
| `Employee_ID` | `employee_id` | BIGINT, primary key | Synthetic employee record identifier | Used only as a key; excluded from model features and public dashboard extracts. |
| `Department` | `department_name` | TEXT, foreign key via department dimension | Department category | Trimmed and standardized to title case. |
| `Gender` | `gender` | TEXT | Source gender category | Kept for aggregate pay-equity analysis only; excluded from attrition scoring. |
| `Age` | `age` | INTEGER | Age in years | Range validated 16–100; excluded from attrition scoring as a protected attribute. |
| `Job_Title` | `job_title` | TEXT, foreign key via role dimension | Job role/title | Trimmed; modeled as a categorical control. |
| `Hire_Date` | `hire_date` | TIMESTAMP | Source hire timestamp | Parsed from `YYYY-MM-DD HH:MM:SS[.ffffff]`; timing is not a resignation event date. |
| `Years_At_Company` | `years_at_company` | NUMERIC(6,2) | Tenure as supplied, years presumed by name | Nonnegative check; not assumed to be measured before resignation. Excluded from attrition scoring, included in pay model. |
| `Education_Level` | `education_level` | TEXT | Education category | Trimmed/title-cased; categorical model feature/control. |
| `Performance_Score` | `performance_score` | NUMERIC(5,2) | Performance score on source scale | Observed values are retained; source provides no rating date. Excluded from attrition scoring, included in pay model. |
| `Monthly_Salary` | `monthly_salary` | NUMERIC(14,2) | Monthly compensation, unit unspecified | Nonnegative check; excluded from attrition scoring, used in aggregate equity analysis. |
| `Work_Hours_Per_Week` | `work_hours_per_week` | NUMERIC(7,2) | Weekly hours, source units | Nonnegative check; candidate attrition feature. |
| `Projects_Handled` | `projects_handled` | INTEGER | Projects handled, count | Nonnegative check; candidate attrition feature. |
| `Overtime_Hours` | `overtime_hours` | NUMERIC(7,2) | Overtime hours, source period unspecified | Nonnegative check; candidate attrition feature. |
| `Sick_Days` | `sick_days` | INTEGER | Sick days, source period unspecified | Nonnegative check; candidate attrition feature. |
| `Remote_Work_Frequency` | `remote_work_frequency` | NUMERIC(6,2) | Remote-work frequency, source scale | Validated 0–100; source values include 0, 25, 50, 75, 100. |
| `Team_Size` | `team_size` | INTEGER | Team size | Validated ≥1. |
| `Training_Hours` | `training_hours` | NUMERIC(7,2) | Training hours, source period unspecified | Nonnegative check; candidate attrition feature. |
| `Promotions` | `promotions` | INTEGER | Promotion count | Nonnegative check; candidate attrition feature. |
| `Employee_Satisfaction_Score` | `employee_satisfaction_score` | NUMERIC(5,2) | Satisfaction score, source scale | Validated 0–5; candidate attrition feature. |
| `Resigned` | `resigned` | BOOLEAN | Whether the synthetic record is marked resigned | Attrition target; parsed from true/false, yes/no or 1/0 forms. No exit date is supplied. |

## Relational design derived from the CSV

The source is **one flat CSV**, not a relational database. The PostgreSQL schema normalizes repeated department and job-title values into dimensions and splits workforce measures, performance, and compensation into one-to-one subject-area tables. `employees.employee_id` is the stable key; all child tables have the same employee grain and a primary/foreign key relationship to `employees`. The employee ABT joins these sources one-to-one, so headcount and salary totals reconcile to the base employee table.

## Missing-value and exclusion rules

- Empty strings are normalized to SQL NULL before conversion.
- Invalid IDs, dates, Boolean values, invalid required categories, or values outside checked ranges are audited. Such records are excluded from the cleaned ABT; exclusions are reported in `v_source_quality` and `sql_verification.txt`.
- Optional measures remain nullable in the schema. The current source file has no blank values, so no imputation was needed.
- Duplicate `Employee_ID` rows are ranked with `ROW_NUMBER()` and only the first deterministic source row is retained. The actual file has no duplicate IDs.
- `Gender`/`Age` are not used for individual attrition scoring. No employee-level prediction is used for employment decisions.
- Pay comparisons are suppressed for group cells with fewer than 30 observations.

## Derived measures

- **Cross-sectional resignation proportion:** resigned records / employee records in the same snapshot. It is not an annual turnover rate.
- **Adjusted pay difference:** gender coefficient from a multiple linear regression controlling for job title, department, tenure, education, and performance. It is an association, not proof of discrimination.
- **Performance and training relationships:** descriptive cross-sectional comparisons; do not imply training causes score changes.
- **Hire-date distribution:** sample composition by supplied hire timestamp; no historical headcount can be reconstructed from this file alone.
