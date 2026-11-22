# R modeling and evaluation

## Dataset limitations relevant to the models

All rows are synthetic. The source has `Resigned`, but no resignation date, outcome window, or timestamps for satisfaction, performance, salary, hours, or other predictors. The logistic model is therefore a **retrospective cross-sectional classification experiment**, not a forecast of future employee exits. It excludes employee ID, age, gender, tenure, salary, and performance from attrition scoring; gender is used only in the aggregate pay audit. Even remaining predictor timing is not independently verified, so model outputs are not suitable for decisions about people.

## Logistic regression

- Stratified 80/20 train/test split, seed 4301.
- 5-fold repeated cross-validation (2 repeats) on training data.
- `caret` center/scale preprocessing is fit within resampling/training only.
- Threshold is selected from out-of-fold training probabilities by F1; test data is not used for threshold selection.
- No synthetic oversampling is used: natural predicted probabilities are preserved. Class imbalance is reported through prevalence, PR-AUC, balanced accuracy, precision/recall and a majority baseline.
- Protected attributes and direct identifiers are not model features. Model scores are exported only as local test rows and as non-identifying department aggregates for dashboard use.

### Observed held-out result

- Test rows: 20,000; observed resignation prevalence: 10.01%.
- ROC-AUC: **0.494**; PR-AUC: **0.097**, below the 0.100 positive prevalence.
- Validation-selected threshold: **0.08**. On the test set this classified every row as resigned: recall 1.000, specificity 0.000, precision 0.100, accuracy 0.100, balanced accuracy 0.500, F1 0.182.
- Majority-class baseline accuracy: **0.900**, balanced accuracy 0.500.
- Confusion matrix: 2,002 true positives; 17,998 false positives; 0 true negatives; 0 false negatives.

This model has no useful ranking signal and performs worse than the simple baseline on accuracy. Do not deploy it, rank employees by its scores, or use it for hiring, dismissal, promotion, pay, or performance decisions. The result is consistent with weak/no predictive signal in this synthetic cross-section; it is not a claim about real organizations.

## Multiple linear compensation model

The response uses raw `Monthly_Salary` because the transformation check did not find the log scale less skewed. Model: salary on gender, job title, department, tenure, education and performance. A random 80/20 split (seed 4301) estimates holdout fit; the inferential coefficient model is fit to all available rows. VIF/GVIF is checked with `car`.

- Rows: 100,000; holdout rows: 19,999.
- R²: **0.9914**; adjusted R²: **0.9914**; holdout RMSE: **127.10**; MAE: **95.03** in unspecified source salary units.
- Reference gender: Male. Adjusted Female coefficient: **+0.18 salary units**, 95% CI **[-1.43, 1.80]**, p = **0.825**. Adjusted Other coefficient: +1.86, 95% CI [-2.27, 5.99], p = 0.377.
- Unadjusted Female vs Male mean gap: **+0.07%**; median gap: **0.00%**. Across 63 department/job-title cells with at least 30 records per compared group, mean gaps ranged from -1.38% to +1.45%; reported median salaries were equal in those source cells.

These are conditional associations within a synthetic dataset. They are not proof of fair pay or discrimination; currency, job architecture and measurement timing are not supplied. Statistical significance does not establish practical importance, and the model must not be used to set individual salaries.
