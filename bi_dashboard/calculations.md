# Tableau calculated fields and validation

All charts should use aggregate-only extracts under `data/processed/`. The SQL exports have different grains, so use a separate source per compatible set of worksheets. Do not join or blend arbitrary aggregate tables to create KPIs. Never connect employee-level ABT, salary ranks or prediction rows.

## Calculated fields

Replace field names below with the exact names in the selected export. For attrition proportion, when the source contains additive counts:

```tableau
IF SUM([employee_count]) = 0 THEN NULL
ELSE SUM([resigned_count]) / SUM([employee_count])
END
```

When using `hr_dashboard_department.csv`, use its precomputed rate/share column if supplied and verify the exact denominator. Compensation means/medians should be taken from the corresponding SQL view. Do not average averages to form a higher-level overall mean. For group-gender gap where female/male fields are both present at compatible grain:

```tableau
IF [male_mean_salary] = 0 THEN NULL
ELSE 100.0 * ([female_mean_salary] - [male_mean_salary]) / [male_mean_salary]
END
```

Label compensation as source salary units because currency is unspecified. Use minimum group-size suppression implemented in `v_compensation_by_role_gender`; do not un-suppress small groups through a second source.

## Cross-checks

1. Workforce KPI counts equal `workforce_overview.csv`; department headcounts sum to total employees.
2. Resignation count totals equal 10,010 and workforce total is 100,000. Overall share should display 10.01%.
3. Department count/share use the same employee denominator. Compare bars with the SQL output, not a recomputed row-level Tableau view.
4. The attrition model card shows ROC-AUC 0.494 and PR-AUC 0.097 versus prevalence 0.100; do not portray it as an operational predictor.
5. Compensation figures reconcile to the corresponding aggregate export; gender comparisons show denominators and suppression.
6. Filters must be scoped to compatible worksheet sources, with no cross-grain duplication.

The Tableau workbook now implements the conditional resignation-rate calculation using additive counts, formats the result as a percentage, and includes the aggregate attrition evaluation as a cautionary view. Confirm dashboard filter behavior and totals in Tableau. The retrospective model is not an employee-level scoring tool.
