# Evidence-based HR actions (synthetic data only)

Every result below comes from the supplied synthetic dataset. Faculty approval was confirmed by the student, but these findings are not evidence about a real employer. Use the actions as viva discussion examples and revalidate against lawful, dated, real organizational data before any policy decision.

## 1. Do not operationalize the attrition score

- **Evidence:** held-out ROC-AUC 0.494; PR-AUC 0.097 vs 0.100 positive prevalence. The F1-selected threshold classified all 20,000 test records as resigned (specificity 0%, accuracy 10%); the majority baseline accuracy was 90%.
- **Interpretation:** the model provides no useful separation and is worse than a no-skill baseline for practical ranking.
- **Action:** do not generate employee risk lists. If a real retention model is later considered, first collect lawful, time-stamped pre-event features and actual resignation dates; validate a prospective time-based cohort and subgroup performance.
- **Success metric:** held-out PR-AUC above prevalence, improved balanced accuracy and calibration, with documented decision thresholds and human review.
- **Limitation:** synthetic cross-section, no event dates or predictor timestamps.

## 2. Investigate local patterns without targeting a department from this file

- **Evidence:** department resignation proportions ranged from 9.56% in IT to 10.54% in Finance, a spread of about 0.98 percentage points. Overall cross-sectional proportion was 10.01% (10,010/100,000).
- **Interpretation:** the synthetic department differences are small and cannot identify a real high-risk unit.
- **Action:** in real HR data, validate exit reasons, role mix and manager-level context before launching a department-specific intervention; compare voluntary/involuntary exits and denominators.
- **Success metric:** dated voluntary turnover and retention by role/department, with confidence intervals and stable reporting periods.
- **Limitation:** this dataset has no separation date or exit reason; its status is cross-sectional.

## 3. Pilot workload and learning changes with measured outcomes

- **Evidence:** resignation proportions were 9.65% for 0 overtime hours and about 10.06% for 11+ hours; training-band proportions were 9.41%–10.19%. Spearman correlation between training hours and performance score was 0.002; between weekly hours and performance score was -0.006.
- **Interpretation:** no meaningful monotonic association appears in these synthetic measures; more hours cannot be assumed to mean better performance.
- **Action:** if a real team identifies a workload or learning concern, run a small opt-in pilot with a pre-specified quality, satisfaction and workload measure rather than applying a blanket hours or training target.
- **Success metric:** pre/post task quality, satisfaction, overtime and retention, reported with uncertainty.
- **Limitation:** cross-sectional synthetic data cannot estimate intervention effects or identify the time window for hour totals.

## 4. Maintain a role-based pay audit with sample suppression

- **Evidence:** unadjusted Female vs Male mean gap was +0.07% and median gap 0%; adjusted Female coefficient was +0.18 source salary units (95% CI -1.43 to +1.80, p=0.825). Role-cell mean gaps with at least 30 observations per group ranged from -1.38% to +1.45%.
- **Interpretation:** this synthetic sample shows no material adjusted gender difference; salary units are unspecified.
- **Action:** on real payroll data, audit comparable job levels and pay bands annually, suppress small cells, review confidence intervals and investigate material unexplained differences with HR/legal context.
- **Success metric:** percentage of eligible role cells reviewed, adjusted gap estimates with confidence intervals, and closure of documented review items.
- **Limitation:** synthetic labels, unspecified currency, incomplete job architecture and possible omitted pay factors; regression does not prove discrimination or fairness.
