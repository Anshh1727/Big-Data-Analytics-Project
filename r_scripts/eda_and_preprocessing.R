#!/usr/bin/env Rscript
# Descriptive HR analysis only; no causal interpretation is implied.
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)
script_path <- if (length(file_arg)) sub("^--file=", "", file_arg[[1]]) else "r_scripts/eda_and_preprocessing.R"
project_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
.libPaths(c(file.path(project_root, "r_lib"), .libPaths()))
suppressPackageStartupMessages({library(dplyr); library(ggplot2); library(readr); library(tidyr)})
input_path <- file.path(project_root, "data/processed/employee_abt.csv")
out_dir <- file.path(project_root, "assets/r_model_plots")
processed_dir <- file.path(project_root, "data/processed")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
if (!file.exists(input_path)) stop("Missing PostgreSQL export: ", input_path, ". Run scripts/run_sql_pipeline.sh first.")

hr <- read_csv(input_path, show_col_types = FALSE, na = c("", "NULL")) %>%
  mutate(resigned = as.logical(resigned),
         across(c(age, years_at_company, performance_score, monthly_salary, work_hours_per_week,
                  projects_handled, overtime_hours, sick_days, remote_work_frequency, team_size,
                  training_hours, promotions, employee_satisfaction_score), as.numeric),
         department_name = as.factor(department_name), job_title = as.factor(job_title),
         gender = as.factor(gender), education_level = as.factor(education_level))
if (anyDuplicated(hr$employee_id)) stop("ABT employee_id is not unique.")
if (nrow(hr) == 0L) stop("ABT export has no rows.")

# One-row summary and source-missingness evidence.
overall <- hr %>% summarise(
  employee_records = n(), unique_employee_ids = n_distinct(employee_id),
  active_records = sum(!resigned, na.rm = TRUE), resigned_records = sum(resigned, na.rm = TRUE),
  resignation_proportion = mean(resigned, na.rm = TRUE),
  mean_tenure_years = mean(years_at_company, na.rm = TRUE), median_tenure_years = median(years_at_company, na.rm = TRUE),
  mean_salary_dataset_units = mean(monthly_salary, na.rm = TRUE), median_salary_dataset_units = median(monthly_salary, na.rm = TRUE),
  mean_performance_score = mean(performance_score, na.rm = TRUE), mean_satisfaction = mean(employee_satisfaction_score, na.rm = TRUE),
  mean_work_hours = mean(work_hours_per_week, na.rm = TRUE), mean_training_hours = mean(training_hours, na.rm = TRUE)
)
write_csv(overall, file.path(processed_dir, "r_eda_overall_summary.csv"))
missingness <- tibble(variable = names(hr), missing_count = vapply(hr, function(x) sum(is.na(x)), integer(1)),
                      missing_proportion = missing_count / nrow(hr))
write_csv(missingness, file.path(processed_dir, "r_eda_missingness.csv"))

numeric_fields <- c("age", "years_at_company", "performance_score", "monthly_salary", "work_hours_per_week",
                    "projects_handled", "overtime_hours", "sick_days", "remote_work_frequency", "team_size",
                    "training_hours", "promotions", "employee_satisfaction_score")
summary_table <- hr %>% summarise(across(all_of(numeric_fields),
  list(mean = ~mean(.x, na.rm=TRUE), median = ~median(.x, na.rm=TRUE), sd = ~sd(.x, na.rm=TRUE),
       p05 = ~quantile(.x,.05,na.rm=TRUE), p95 = ~quantile(.x,.95,na.rm=TRUE)))) %>%
  pivot_longer(everything(), names_to = c("variable","statistic"), names_pattern = "^(.*)_(mean|median|sd|p05|p95)$", values_to = "value")
write_csv(summary_table, file.path(processed_dir, "r_eda_numeric_summary.csv"))

outlier_table <- bind_rows(lapply(numeric_fields, function(v) {
  x <- hr[[v]]; q <- quantile(x, c(.25,.75), na.rm=TRUE); spread <- q[[2]]-q[[1]]
  tibble(variable=v, lower_iqr=q[[1]]-1.5*spread, upper_iqr=q[[2]]+1.5*spread,
         flagged_count=sum(x < q[[1]]-1.5*spread | x > q[[2]]+1.5*spread, na.rm=TRUE))
}))
write_csv(outlier_table, file.path(processed_dir, "r_eda_iqr_outlier_flags.csv"))

category_counts <- bind_rows(lapply(c("department_name","job_title","gender","education_level"), function(v) {
  hr %>% count(.data[[v]], name="employee_count") %>% rename(group_value=1) %>% mutate(dimension=v)
}))
write_csv(category_counts, file.path(processed_dir, "r_eda_category_counts.csv"))

cor_data <- hr %>% select(all_of(numeric_fields))
cor_mat <- cor(cor_data, use="pairwise.complete.obs", method="spearman")
cor_df <- as.data.frame(as.table(cor_mat)) %>% rename(feature_x=Var1, feature_y=Var2, spearman_rho=Freq)
write_csv(cor_df, file.path(processed_dir, "r_eda_spearman_correlations.csv"))
p_corr <- ggplot(cor_df, aes(feature_x, feature_y, fill=spearman_rho)) + geom_tile() +
  scale_fill_gradient2(low="#B84A62", mid="white", high="#267A75", limits=c(-1,1)) +
  labs(title="Spearman correlations across workforce measures", x=NULL, y=NULL, fill="Spearman rho") +
  theme_minimal(base_size=10) + theme(axis.text.x=element_text(angle=45,hjust=1))
ggsave(file.path(out_dir,"workforce_correlation_heatmap.png"),p_corr,width=11,height=9,dpi=220)

p_department <- hr %>% group_by(department_name) %>% summarise(resignation_proportion=mean(resigned), employee_count=n(),.groups="drop") %>%
  ggplot(aes(reorder(department_name,resignation_proportion),resignation_proportion)) + geom_col(fill="#246B8E") + coord_flip() +
  scale_y_continuous(labels=function(x) paste0(round(100*x,1),"%")) +
  labs(title="Cross-sectional resignation proportion by department",subtitle="Not a period-based turnover rate",x=NULL,y="Resigned records / employee records") + theme_minimal()
ggsave(file.path(out_dir,"resignation_by_department.png"),p_department,width=9,height=6,dpi=220)

p_satisfaction <- ggplot(hr,aes(factor(employee_satisfaction_score),fill=factor(resigned,labels=c("Active","Resigned")))) +
  geom_bar(position="fill") + scale_y_continuous(labels=function(x) paste0(round(100*x),"%")) +
  labs(title="Resignation proportion across satisfaction scores",x="Employee satisfaction score",y="Share within score",fill="Status") + theme_minimal()
ggsave(file.path(out_dir,"resignation_by_satisfaction.png"),p_satisfaction,width=8,height=5,dpi=220)

p_performance <- ggplot(hr,aes(department_name,performance_score,fill=department_name)) + geom_boxplot(outlier.alpha=.15,show.legend=FALSE) + coord_flip() +
  labs(title="Performance score distribution by department",x=NULL,y="Performance score (source scale)") + theme_minimal()
ggsave(file.path(out_dir,"performance_by_department.png"),p_performance,width=9,height=6,dpi=220)

p_training <- ggplot(hr,aes(training_hours,performance_score,color=department_name)) + geom_point(alpha=.18) +
  geom_smooth(method="lm",se=TRUE,color="#BF6B36") +
  labs(title="Training hours and performance score",subtitle="Cross-sectional association; not a causal training effect",x="Training hours (source units)",y="Performance score") + theme_minimal()
ggsave(file.path(out_dir,"training_vs_performance.png"),p_training,width=9,height=6,dpi=220)

p_workload <- ggplot(hr,aes(work_hours_per_week,performance_score,color=factor(resigned,labels=c("Active","Resigned")))) +
  geom_point(alpha=.22) + geom_smooth(method="lm",formula=y~x,se=FALSE) +
  labs(title="Work hours and performance score",subtitle="Longer hours are not assumed to mean higher productivity",x="Work hours per week",y="Performance score",color="Status") + theme_minimal()
ggsave(file.path(out_dir,"work_hours_vs_performance.png"),p_workload,width=9,height=6,dpi=220)

p_salary <- ggplot(hr,aes(department_name,monthly_salary,fill=department_name)) + geom_boxplot(outlier.alpha=.12,show.legend=FALSE) + coord_flip() +
  labs(title="Monthly salary distribution by department",subtitle="Salary units/currency not specified in source metadata",x=NULL,y="Monthly salary (dataset units)") + theme_minimal()
ggsave(file.path(out_dir,"salary_by_department.png"),p_salary,width=9,height=6,dpi=220)

p_resign_overtime <- hr %>% mutate(overtime_band=cut(overtime_hours,breaks=c(-Inf,0,5,10,Inf),labels=c("0","1–5","6–10","11+"))) %>%
  group_by(overtime_band) %>% summarise(resignation_proportion=mean(resigned),employee_count=n(),.groups="drop") %>%
  ggplot(aes(overtime_band,resignation_proportion)) + geom_col(fill="#C67D32") +
  scale_y_continuous(labels=function(x) paste0(round(100*x,1),"%")) +
  labs(title="Cross-sectional resignation proportion by overtime band",x="Overtime hours (source units)",y="Resigned records / employee records") + theme_minimal()
ggsave(file.path(out_dir,"resignation_by_overtime.png"),p_resign_overtime,width=8,height=5,dpi=220)

p_hire <- hr %>% mutate(hire_month=as.Date(format(hire_date,"%Y-%m-01"))) %>% count(hire_month) %>%
  ggplot(aes(hire_month,n)) + geom_col(fill="#267A75") +
  labs(title="Hire-date distribution in the synthetic employee sample",subtitle="Sample composition only; not historical headcount",x="Hire month",y="Employee records") + theme_minimal()
ggsave(file.path(out_dir,"hire_date_sample_distribution.png"),p_hire,width=10,height=5,dpi=220)

cat("EDA finished: ",nrow(hr),"employee records; summaries in data/processed and plots in assets/r_model_plots.\n",sep="")
