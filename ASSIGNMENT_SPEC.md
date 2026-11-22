# Codex implementation brief — BA4301

## Instructions for Codex

Act as an experienced data analyst, SQL developer, R statistical programmer and BI developer. Build the complete, reproducible assignment in the current project folder, not merely a tutorial or a proposed architecture. The faculty requirements reproduced below are authoritative. The implementation guidance in this section is supplementary, not additional faculty requirements.

- Inspect the workspace first; preserve existing useful files. If no domain, dataset or stack is already chosen, propose a suitable default and explain the choice. Prefer a real, openly available multi-table dataset with at least 100,000 records where practical, meaningful business questions and a suitable modeling target. Choose one domain and one dataset, not all listed alternatives. Verify the source, license, schema and actual row counts before committing to it. If download requires credentials or manual acceptance, provide exact instructions and mark it blocked; never substitute synthetic data silently.
- Use SQL for extraction and transformation, R for EDA and statistical modeling, and either Power BI or Tableau for the actual interactive dashboard. Do not replace these with Python modeling or a custom HTML dashboard. Python/shell may be used for auxiliary automation only.
- Prefer PostgreSQL and Tableau Public/Desktop on macOS if no stack was specified (Power BI Desktop requires a compatible Windows environment). Choose and document the actual stack. Do not assume that a BI editor, R, database server or external account is available; check first.
- Implement in dependency order: dataset → schema/import → cleaning → analytical base table (ABT) → R EDA → R model/evaluation → BI-ready exports → dashboard → recommendations → portfolio documentation. Run each stage where tooling/data permit; fix errors before moving on. Do not stop after scaffolding.
- Keep the mandatory filenames and directories from the faculty instructions below. Save a copy of this brief as `ASSIGNMENT_SPEC.md` before replacing the root `README.md` with the final project-specific executive documentation. Do not present this assignment brief itself as the finished project README.
- Never invent row counts, results, model scores, screenshots, public URLs or publication status. Use actual outputs and clearly mark blocked/manual tasks. Do not publish, upload or post through personal accounts without user authorization.

## Implementation plan and acceptance criteria

### 0. Dataset and reproducibility

Document the exact source URL, dataset name/version, access date, license/redistribution conditions, original tables and row counts, key relationships, analytical grain, business problem, target audience and 3–5 analytical questions. Create `data/data_dictionary.md` with columns, types, meanings, keys, units, missing-value rules and derived features. Store raw downloads locally in `data/raw/` and processed exports in `data/processed/` as appropriate; ignore large/restricted source files and secrets in `.gitignore`. Provide `.env.example` if credentials are needed; never commit real secrets. Provide prerequisites, database setup/import commands, R package installation and exact execution order in the final README. Use relative paths and a reproducible random seed where relevant.

### 1. SQL pipeline (4 marks)

- `sql/01_schema_setup.sql`: create tables, keys and suitable data types; document and implement reproducible imports, including any necessary engine-specific import commands.
- `sql/02_data_cleaning.sql`: inspect data quality, handle nulls with documented rules, cast types, check duplicates and invalid records, and build the ABT with meaningful INNER and LEFT JOIN examples. Use CASE WHEN, COALESCE and CAST explicitly. Avoid unintended many-to-many row multiplication; document the ABT grain.
- `sql/03_analytical_queries.sql`: implement meaningful GROUP BY aggregations, CTEs, and window calculations using PARTITION BY and suitable ranking or moving-average functions. Produce the final analysis-ready view/table and reproducible CSV exports for R and BI.
- Verify source and output row counts, key uniqueness at the intended grain, null treatment, join coverage and aggregate consistency. Save actual query-result evidence in `assets/sql_output_screenshots/`; if screenshots cannot be captured, save query outputs separately and provide instructions for genuine screenshots.

### 2. R EDA and modeling (4 marks)

- `r_scripts/eda_and_preprocessing.R`: read the SQL export using R, use dplyr and ggplot2, calculate summary statistics, inspect missing values and outliers, visualize distributions and relevant feature correlations, and save plots with descriptive filenames in `assets/r_model_plots/`.
- `r_scripts/predictive_model.R`: implement at least one faculty-approved regression, classification or K-means model in R appropriate to the chosen problem. Explain feature selection, preprocessing and model choice. For supervised learning, use a suitable held-out evaluation or time-based split, fit preprocessing only on training data, prevent target leakage, and evaluate with appropriate metrics (e.g., R²/RMSE for regression; confusion matrix, accuracy, precision and recall for classification). For K-means, scale relevant features and assess cluster quality using silhouette or another justified diagnostic. Interpret coefficients, feature effects or cluster profiles as appropriate.
- Save actual metric values, diagnostic plots and scored predictions/segment labels, including stable join keys for BI. Distinguish held-out metrics from training results. Ensure the exported keys relate correctly to the ABT. Document limitations; do not claim causal relationships from observational analysis.

### 3. Interactive executive dashboard (4 marks)

Create 2–3 genuine interactive pages (aim for 3 to support the resume format): (1) executive KPIs and overview, (2) trends and operational/business drivers, and (3) predictive findings/segments and managerial actions. Adapt page titles to the selected domain.

Connect both the cleaned SQL outputs and R predictions; document data relationships and verify that joining predictions does not double-count KPIs. Use consistent formatting, meaningful titles and readable charts; include KPI cards, slicers/filters, cross-filtering and appropriate drill-downs. For Power BI include explicit DAX formulas with CALCULATE, DIVIDE, dynamic KPI conditions and relevant time intelligence; for Tableau include explicit calculated fields with FIXED LOD and conditional aggregations. Save formulas in `bi_dashboard/calculations.md` and test against SQL/R results. Explain any calculation that is genuinely inapplicable rather than manufacturing data to support it.

Deliver the genuine `bi_dashboard/dashboard_file.pbix` OR `bi_dashboard/dashboard_file.twbx`, plus `bi_dashboard/bi_web_link.txt` containing the verified public interactive dashboard URL once published. Capture high-resolution screenshots of each real dashboard page and interactive filter views under `assets/dashboard_previews/`. If the required BI application or public publishing account is unavailable, provide a complete manual build/publishing guide with exact data sources, relationships, calculated fields, per-page chart configurations, filter actions and layout. Mark the native workbook, previews or live URL as pending until actually obtained. Do not create fake binary files, placeholder links presented as live links, or fabricated dashboard screenshots. A guide alone does not satisfy the faculty dashboard deliverable.

### 4. Documentation, showcase and resume (4 marks)

Create `README.md` as a polished project-specific executive document. Include all seven mandatory sections specified below, actual results, relative Markdown image embeds of real screenshots and diagnostic plots, a dataset citation, reproducible setup/run instructions, and the real public BI/GitHub links once available. Include 2–3 advanced SQL snippets with explanations, model validation and interpretation, and 3–5 specific evidence-backed managerial recommendations.

Create `showcase/linkedin_post.md` with the business problem, explicit stack, two verified findings, relevant hashtags, faculty/college tagging instructions and GitHub/BI links (clearly labeled pending until available). Prepare a multi-slide PDF carousel or high-resolution images using actual SQL evidence, R evaluation and dashboard previews. Create `showcase/resume_bullets.md` with the prescribed project title format and three concise bullets containing actual processed counts, validated metrics, dashboard page count and recommendation count. The PDF's 75,000+ records and 84% accuracy/0.78 ROC-AUC are illustrative, not required outcomes. Do not copy them as measured results.

Provide setup/publishing instructions for a dedicated public GitHub repository using the student's personal email/account. The student must review and authorize publication, complete LinkedIn tagging/posting and add the project to their resume. Only publish data permitted for redistribution; remember that public BI publishing may expose underlying data.

### 5. Final verification and handover

Create `SUBMISSION_CHECKLIST.md` with evidence paths and status (Done / Pending / Blocked) for each item below. Mark Done only after verification. Include errors encountered, exact commands to reproduce, and remaining manual steps. Check all four rubric categories equally; no category may be skipped.

- [ ] One real eligible domain dataset, documented source and measured size/schema.
- [ ] Three required SQL scripts and reproducible database import, joins, cleaning, aggregations, CTEs, windows, verified ABT and exports.
- [ ] Two required R scripts; EDA plots, model execution, validation, interpretation and scored exports.
- [ ] Native Power BI/Tableau file; 2–3 pages, working KPI cards, filters/cross-filtering, calculations, trends and predictive views; public BI URL verified.
- [ ] Data dictionary and original repository structure, real SQL screenshots, R plots and dashboard previews.
- [ ] Final executive README with all seven required sections, including embedded screenshots and 3–5 evidence-based recommendations.
- [ ] Public GitHub repository verified; LinkedIn draft/media, public post and tags verified when authorized; resume bullets prepared with real figures and integrated by student.
- [ ] End-to-end execution tested and documented; all outstanding blockers listed honestly.

At handover, report the selected dataset/domain/stack, generated files, actual records and results, tests executed, dashboard status and precise remaining steps. The goal is a working submission covering the entire 16-mark rubric; do not promise full marks or claim incomplete external tasks are complete.

---

# Original faculty assignment requirements (preserved below)

**Nagar Yuwak Shikshan Sanstha's**  
**DMIMS**  
**Datta Meghe Institute of Management Studies**  
*AN AUTONOMOUS INSTITUTE AFFILIATED TO RASHTRASANT TUKADOJI MAHARAJ NAGPUR UNIVERSITY WITH NBA ACCREDITED MBA PROGRAM*

---

# BA4301: Big Data Analytics Assignment

A strong applied portfolio is the single best differentiator on your resume when applying for Business Analyst, Data Analyst, or Analytics Consultant roles.

As part of BA4301: Big Data Analytics, you are required to build an end-to-end, multi-stage analytics project using a real-world open-source dataset. Your project must integrate the complete analytics stack: SQL for database querying and data wrangling, R for exploratory data analysis (EDA) and statistical/predictive modeling, and Power BI or Tableau for interactive executive dashboarding.

The entire workflow must be documented in a public GitHub repository, showcased on LinkedIn, and integrated into your resume.

---

## 1. Project Scope & Domain Selection

Select a single domain-specific dataset (minimum 50,000-100,000 rows or multi-table relational schema) from Kaggle, Maven Analytics, Data.gov.in, or Google Cloud Public Datasets:

* **Marketing & Customer Analytics:** Customer churn prediction, RFM customer segmentation, campaign conversion analysis.
* **Finance & Banking:** Credit risk/loan default classification, transaction fraud indicators, portfolio performance.
* **HR Analytics:** Employee attrition modeling, workforce performance patterns, compensation equity.
* **Operations & Supply Chain:** Delivery lead-time regression, inventory stockout prediction, order fulfillment dynamics.
* **Healthcare / Retail Analytics:** Patient readmission drivers, retail store sales forecasting, market basket analysis.

---

## 2. End-to-End Analytics Pipeline

Your submission must clearly demonstrate how raw business data moves through extraction, statistical modeling, and visual decision-making:

```text
[Raw Relational/CSV Data]
        |
        v
[Phase 1: SQL Data Extraction & Transformation]
• Aggregations, CTEs, Window Functions, Joins
        |
        v
[Phase 2: R Statistical Modeling & EDA]
• Summary stats, correlation, regression/classification/clustering
        |
        v
[Phase 3: Power BI / Tableau Executive Dashboard]
• Calculated measures (DAX / Calculated Fields), interactive visuals
        |
        v
[Actionable Business Strategy & Recommendations]
```

### Phase 1: Data Extraction & Transformation (SQL)

* Store the raw data into a database or query it using standard SQL (PostgreSQL, MySQL, SQLite, or BigQuery sandbox).
* Write structured SQL queries demonstrating:
  * Table joins (Inner/Left) to build your master analytical base table (ABT).
  * Data cleaning, handling nulls/type casting (`CASE WHEN`, `COALESCE`, `CAST`).
  * Aggregations and window functions (`ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`, `PARTITION BY`, or moving averages).
  * Common Table Expressions (CTEs) or Subqueries to prepare analysis-ready datasets.
* Export the clean, modeled analytical view/table for analysis in R and reporting in BI.

### Phase 2: Exploratory Analytics & Predictive Modeling (R)

* Load the SQL-extracted dataset into R / RStudio.
* Conduct structured Exploratory Data Analysis (EDA) using `dplyr` and `ggplot2` to visualize distributions, outliers, and feature correlations.
* Implement at least one statistical or machine learning model aligned with Unit-4 / Unit-5 syllabus outcomes:
  * **Regression Analysis:** Multiple Linear or Logistic Regression for prediction/probability scoring.
  * **Clustering:** K-Means clustering to create distinct customer or operational segments.
  * **Classification:** Naïve Bayes Classifier or Logistic Classification for churn/risk categorization.
* Evaluate model fit (e.g., R², RMSE, Confusion Matrix, Accuracy, Precision/Recall, or Silhouette score) and export scored outputs/predictions for dashboarding.

### Phase 3: Executive Dashboard Design (Power BI or Tableau)

* Connect your cleaned SQL data and model prediction outputs into Power BI Desktop or Tableau Desktop/Public.
* **Calculations:**
  * If using Power BI: Write explicit DAX measures (`CALCULATE`, `DIVIDE`, dynamic KPI conditions, time-intelligence).
  * If using Tableau: Write explicit Calculated Fields (Level of Detail/LOD expressions like `FIXED`, conditional aggregations).
* **Dashboard Layout:** Design an intuitive 2-to-3 page dashboard featuring high-level KPI cards, interactive slicers, cross-filtering, and dedicated views for operational trends and predictive model findings.
* **Business Recommendations:** Conclude with 3 to 5 clear, data-driven managerial actions derived from your findings.

---

## 3. GitHub Repository Structure

Create a dedicated public GitHub repository using your personal email ID with the following directory organization:

```text
data/
  data_dictionary.md          <- Data dictionary & link to raw data source
sql/
  01_schema_setup.sql         <- Table definitions & data import
  02_data_cleaning.sql        <- ETL, null handling, joins, transformations
  03_analytical_queries.sql   <- CTEs, window functions, and final analysis view
r_scripts/
  eda_and_preprocessing.R     <- Summary stats & ggplot visualizations
  predictive_model.R          <- Model execution, diagnostics & evaluation
bi_dashboard/
  dashboard_file.pbix/.twbx   <- Power BI (.pbix) or Tableau Packaged (.twbx)
  bi_web_link.txt             <- Public link to Power BI Service / Tableau Public
assets/
  sql_output_screenshots/     <- Query results & verification previews
  r_model_plots/              <- Model curves, confusion matrices, or cluster plots
  dashboard_previews/         <- High-res screenshots of dashboard pages
README.md                     <- Project executive documentation
```

### Required Sections in README.md:

1. **Project Title & Executive Summary:** Problem definition, business relevance, and scope.
2. **Tech Stack:** SQL (engine name), R (key packages: tidyverse, caret, etc.), Power BI / Tableau.
3. **Data Pipeline & Architecture:** Flowchart or brief explanation tracing data movement from SQL → R → BI.
4. **Key SQL Code Highlights:** Highlight 2 to 3 advanced queries (CTEs, Window Functions) with brief commentary on why they were necessary.
5. **R Modeling Insights & Validation:** Highlight model findings, diagnostic plots, and interpretation of key coefficients or clusters.
6. **Dashboard Preview:** Embedded screenshots showing each page and interactive filter views.
7. **Business Insights & Strategic Recommendations:** 3 to 5 bullet points defining concrete organizational decisions management should take based on the data.

---

## 4. LinkedIn Showcase & Placement Cell Verification

Once your repository is ready, showcase your project publicly on LinkedIn:

* **Post Content:**
  * Briefly introduce the business problem and your targeted industry domain.
  * State the tech stack explicitly: SQL + R + Power BI / Tableau.
  * Highlight 2 major statistical findings or predictive model takeaways.
  * Attach a multi-slide PDF carousel or high-resolution images showcasing your SQL logic, R evaluation plot, and final dashboard pages.
* **Links:** Provide direct links to your GitHub repository and live interactive BI dashboard.
* **Tagging & Hashtags:** Tag the faculty instructor and the college page. Use relevant industry hashtags: `#DataAnalytics` `#SQL` `#RStats` `#PowerBI` `#Tableau` `#BigDataAnalytics` `#BusinessIntelligence`.

---

## 5. Resume Integration Format

Add this project directly under the Projects section of your resume:

> **End-to-End [Domain] Predictive Analytics & BI Dashboard | SQL, R, Power BI, Advanced Modeling**  
> **GitHub:** [Hyperlink to your Public Repository URL]
> * Extracted, cleaned, and transformed 75,000+ relational records using SQL (CTEs, multi-table joins, and window functions) to construct a centralized analytical base table.
> * Built and validated a predictive [Regression / Classification / K-Means] model in R, achieving [e.g., 84% accuracy / 0.78 ROC-AUC] in identifying [churn risk / operational bottlenecks / high-value clusters].
> * Designed an interactive 3-page Power BI / Tableau dashboard with custom measures and drill-downs, translating model findings into 4 data-driven strategies for managerial decision-making.

---

## Evaluation Criteria (16 Marks - Teacher's Assessment)

| Component | Focus Area | Weightage |
| :--- | :--- | :--- |
| **SQL Pipeline** | Query structure, proper use of joins, CTEs, aggregation, and window functions | 4 Marks |
| **R Modeling & EDA** | Quality of exploratory analysis, model execution, evaluation metrics, and interpretation | 4 Marks |
| **BI Dashboard Design** | Visual hierarchy, measure engineering (DAX/Calculated fields), usability, and UI consistency | 4 Marks |
| **Documentation & Showcase** | GitHub README quality, reproducible code, LinkedIn showcase post, and resume bullet | 4 Marks |

---

*Vishwadeep M.*