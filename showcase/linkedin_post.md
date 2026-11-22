# LinkedIn showcase draft — review before posting

I built an end-to-end HR analytics workflow with PostgreSQL, R and Tableau Public using an instructor-approved synthetic employee dataset.

The SQL pipeline validated and normalized 100,000 records; R produced EDA and evaluated an attrition classifier and compensation model. The attrition classifier did not show useful ranking signal (held-out ROC-AUC 0.494; PR-AUC 0.097 versus 0.100 prevalence), so the project explicitly recommends against using it for employee decisions. A compensation model achieved holdout MAE 95.03 in unspecified source units, with important limitations around the synthetic data and missing context.

**Tableau status:** The packaged workbook is published with three dashboard tabs visible. It uses aggregate extracts from an instructor-approved synthetic dataset.

**Links:**
- GitHub: https://github.com/Anshh1727/Big-Data-Analytics-Project
- Tableau Public: https://public.tableau.com/app/profile/anshu.lihitkar/viz/HRAnalyticsWorkforceAttritionCompensation/CompensationEquity

Tag the instructor and college only after confirming their official profile URLs. Suggested hashtags: #HRAnalytics #SQL #RStats #Tableau #PeopleAnalytics #DataAnalytics.

## Carousel checklist

Carousel media has not been created. Create slides only from genuine artifacts: project question/data caveat; SQL architecture and actual verification; R EDA; attrition evaluation including its failed result; pay analysis with units/limitations; actual Tableau dashboard screenshots; recommendations and verified links.
