#!/usr/bin/env Rscript
# Retrospective attrition classification and aggregate pay-equity inference.
# The source has no outcome/event timestamps: this is not a validated future forecast.
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)
script_path <- if (length(file_arg)) sub("^--file=", "", file_arg[[1]]) else "r_scripts/predictive_model.R"
project_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
.libPaths(c(file.path(project_root, "r_lib"), .libPaths()))
suppressPackageStartupMessages({library(dplyr); library(readr); library(ggplot2); library(caret); library(pROC); library(broom); library(car)})
set.seed(4301)
input_path <- file.path(project_root,"data/processed/employee_abt.csv")
out_dir <- file.path(project_root,"assets/r_model_plots")
processed_dir <- file.path(project_root,"data/processed")
dir.create(out_dir,recursive=TRUE,showWarnings=FALSE)
if(!file.exists(input_path)) stop("Missing PostgreSQL ABT export: ",input_path)
hr <- read_csv(input_path,show_col_types=FALSE,na=c("","NULL")) %>%
  mutate(resigned=as.logical(resigned),
         across(c(age,years_at_company,performance_score,monthly_salary,work_hours_per_week,
                  projects_handled,overtime_hours,sick_days,remote_work_frequency,team_size,
                  training_hours,promotions,employee_satisfaction_score),as.numeric),
         across(c(department_name,job_title,education_level,gender),as.factor))
if(anyDuplicated(hr$employee_id)) stop("Employee-level ABT key must be unique.")

# ---------------- Model 1: logistic regression (retrospective classification) ----------------
# Employee_ID is a key, not a feature. Age and gender are protected attributes and are
# excluded. Salary/performance/tenure are excluded from scoring because their timing
# relative to resignation is not documented. No event timestamps exist in the source.
attrition_features <- c("department_name","job_title","education_level",
  "work_hours_per_week","projects_handled","overtime_hours","sick_days",
  "remote_work_frequency","team_size","training_hours","promotions",
  "employee_satisfaction_score")
attrition_df <- hr %>% select(employee_id,resigned,all_of(attrition_features)) %>%
  filter(complete.cases(.)) %>%
  mutate(attrition=factor(if_else(resigned,"Resigned","Active"),levels=c("Resigned","Active"))) %>%
  select(-resigned)
if(n_distinct(attrition_df$attrition)<2) stop("Attrition model requires both observed outcome classes.")
set.seed(4301)
train_idx <- createDataPartition(attrition_df$attrition,p=.80,list=FALSE)
train_df <- attrition_df[train_idx,,drop=FALSE]
test_df <- attrition_df[-train_idx,,drop=FALSE]
if(n_distinct(train_df$attrition)<2 || n_distinct(test_df$attrition)<2) stop("Train/test split does not contain both classes.")
ctrl <- trainControl(method="repeatedcv",number=5,repeats=2,
  classProbs=TRUE,summaryFunction=twoClassSummary,savePredictions="final",
  allowParallel=FALSE)
formula_attrition <- reformulate(attrition_features,response="attrition")
set.seed(4301)
attrition_fit <- train(formula_attrition,data=train_df,method="glm",family=binomial(),
  metric="ROC",trControl=ctrl,preProcess=c("center","scale"),na.action=na.fail)

# Choose a threshold from out-of-fold training predictions only, optimizing F1 for
# the minority/event class. Test data is not consulted until final evaluation.
oof <- attrition_fit$pred
if(is.null(oof) || !("Resigned" %in% names(oof))) stop("Cross-validation probabilities were not saved by caret.")
threshold_grid <- seq(.01,.99,by=.01)
f1_for <- function(actual,prob,threshold) {
  pred <- prob >= threshold
  tp <- sum(pred & actual); fp <- sum(pred & !actual); fn <- sum(!pred & actual)
  if(tp+fp==0 || tp+fn==0) return(0)
  2*tp/(2*tp+fp+fn)
}
oof_actual <- oof$obs=="Resigned"
oof_scores <- oof$Resigned
threshold_scores <- vapply(threshold_grid,function(t) f1_for(oof_actual,oof_scores,t),numeric(1))
selected_threshold <- max(threshold_grid[threshold_scores==max(threshold_scores)])

prob_test <- predict(attrition_fit,newdata=test_df,type="prob")[,"Resigned"]
pred_test <- factor(if_else(prob_test>=selected_threshold,"Resigned","Active"),levels=c("Resigned","Active"))
truth_test <- test_df$attrition
cm <- table(predicted=pred_test,actual=truth_test)
tp <- sum(pred_test=="Resigned" & truth_test=="Resigned")
fp <- sum(pred_test=="Resigned" & truth_test=="Active")
fn <- sum(pred_test=="Active" & truth_test=="Resigned")
tn <- sum(pred_test=="Active" & truth_test=="Active")
accuracy <- (tp+tn)/sum(cm)
recall <- if(tp+fn>0) tp/(tp+fn) else NA_real_
specificity <- if(tn+fp>0) tn/(tn+fp) else NA_real_
precision <- if(tp+fp>0) tp/(tp+fp) else 0
f1 <- if(2*tp+fp+fn>0) 2*tp/(2*tp+fp+fn) else 0
balanced_accuracy <- mean(c(recall,specificity),na.rm=TRUE)
roc_obj <- roc(response=truth_test,predictor=as.numeric(prob_test),levels=c("Active","Resigned"),direction="<",quiet=TRUE)
roc_auc <- as.numeric(auc(roc_obj))
pr_auc <- function(actual,score) {
  positive_n <- sum(actual)
  if(positive_n==0 || positive_n==length(actual)) return(NA_real_)
  ord <- order(score,decreasing=TRUE); tp_c <- cumsum(actual[ord]); fp_c <- cumsum(!actual[ord])
  recall <- c(0,tp_c/positive_n); precision <- c(1,tp_c/pmax(tp_c+fp_c,1))
  sum(diff(recall)*(head(precision,-1)+tail(precision,-1))/2)
}
pr_area <- pr_auc(truth_test=="Resigned",as.numeric(prob_test))
brier <- mean((as.numeric(prob_test)-(truth_test=="Resigned"))^2)
# A no-skill majority-class baseline, scored on the held-out test sample.
majority <- names(which.max(table(train_df$attrition)))[1]
baseline_pred <- factor(rep(majority,nrow(test_df)),levels=c("Resigned","Active"))
btp <- sum(baseline_pred=="Resigned" & truth_test=="Resigned"); bfp <- sum(baseline_pred=="Resigned" & truth_test=="Active")
bfn <- sum(baseline_pred=="Active" & truth_test=="Resigned"); btn <- sum(baseline_pred=="Active" & truth_test=="Active")
baseline_accuracy <- (btp+btn)/length(truth_test)
baseline_recall <- if(btp+bfn>0) btp/(btp+bfn) else NA_real_
baseline_specificity <- if(btn+bfp>0) btn/(btn+bfp) else NA_real_
baseline_balanced <- mean(c(baseline_recall,baseline_specificity),na.rm=TRUE)

attrition_metrics <- tibble(model="Logistic regression, stratified 80/20 holdout",
  seed=4301,training_n=nrow(train_df),test_n=nrow(test_df),
  observed_resignation_prevalence=mean(attrition_df$attrition=="Resigned"),
  test_resignation_prevalence=mean(truth_test=="Resigned"),threshold=selected_threshold,
  accuracy=accuracy,balanced_accuracy=balanced_accuracy,precision=precision,recall=recall,
  f1=f1,specificity=specificity,roc_auc=roc_auc,pr_auc=pr_area,brier_score=brier,
  baseline_majority_class=majority,baseline_accuracy=baseline_accuracy,baseline_balanced_accuracy=baseline_balanced,
  cv_method="5-fold repeated 2x; threshold selected from out-of-fold training predictions",
  class_imbalance_method="Stratified split, repeated CV, validation-selected F1 threshold, PR-AUC and balanced metrics; no resampling to preserve natural probability calibration",
  interpretation_limit="Retrospective cross-sectional classification only; source has no dated resignation events or predictor measurement times")
write_csv(attrition_metrics,file.path(processed_dir,"attrition_model_metrics.csv"))

# Long-format, aggregate-only model summary for Tableau. Never export row-level
# prediction scores to a public dashboard; the model is a failed retrospective
# experiment and is included only to communicate its evaluation and limitations.
attrition_tableau_metrics <- tibble::tibble(
  metric = c("ROC-AUC", "PR-AUC", "Observed resignation prevalence",
             "Majority-class baseline accuracy", "Model specificity"),
  value = c(roc_auc, pr_area, mean(truth_test == "Resigned"),
            baseline_accuracy, specificity),
  comparison = c("0.500 = no-skill reference", "0.100 = positive prevalence",
                 "10.01% in held-out test set", "89.99% baseline accuracy",
                 "0.000 at selected threshold"),
  interpretation = c("No useful ranking signal",
                      "Below prevalence baseline",
                      "Test-set outcome share",
                      "Model accuracy is 10.01%",
                      "All test rows predicted positive"),
  use_caution = "Retrospective synthetic classification; not a turnover forecast or employee decision tool"
)
write_csv(attrition_tableau_metrics,
          file.path(processed_dir,"attrition_model_tableau.csv"))
write_csv(as.data.frame.matrix(cm) %>% tibble::rownames_to_column("predicted_class"),file.path(processed_dir,"attrition_confusion_matrix.csv"))
roc_df <- tibble(false_positive_rate=1-roc_obj$specificities,true_positive_rate=roc_obj$sensitivities)
write_csv(roc_df,file.path(processed_dir,"attrition_roc_curve.csv"))
p_roc <- ggplot(roc_df,aes(false_positive_rate,true_positive_rate))+geom_line(color="#246B8E",linewidth=1)+geom_abline(linetype=2)+coord_equal()+
  labs(title="Held-out logistic regression ROC curve",subtitle=paste0("ROC-AUC = ",round(roc_auc,3)),x="False positive rate",y="True positive rate")+theme_minimal()
ggsave(file.path(out_dir,"attrition_roc_curve.png"),p_roc,width=7,height=6,dpi=220)
pr_df <- tibble(actual=truth_test=="Resigned",score=as.numeric(prob_test)) %>% arrange(desc(score)) %>%
  mutate(tp=cumsum(actual),fp=cumsum(!actual),recall=tp/sum(actual),precision=tp/(tp+fp))
write_csv(pr_df,file.path(processed_dir,"attrition_precision_recall_curve.csv"))
p_pr <- ggplot(pr_df,aes(recall,precision))+geom_step(color="#C67D32",linewidth=.8)+
  labs(title="Held-out precision-recall curve",subtitle=paste0("Trapezoidal PR-AUC = ",round(pr_area,3)),x="Recall",y="Precision")+theme_minimal()
ggsave(file.path(out_dir,"attrition_precision_recall_curve.png"),p_pr,width=7,height=6,dpi=220)
p_cm <- as.data.frame(cm) %>% ggplot(aes(actual,predicted,fill=Freq))+geom_tile()+geom_text(aes(label=Freq),size=5)+
  scale_fill_gradient(low="white",high="#246B8E")+labs(title="Held-out confusion matrix",x="Observed class",y="Predicted class")+theme_minimal()
ggsave(file.path(out_dir,"attrition_confusion_matrix.png"),p_cm,width=6,height=5,dpi=220)
calibration <- tibble(observed=as.integer(truth_test=="Resigned"),probability=as.numeric(prob_test)) %>%
  mutate(probability_decile=ntile(probability,10)) %>% group_by(probability_decile) %>%
  summarise(employee_count=n(),mean_predicted_probability=mean(probability),observed_resignation_proportion=mean(observed),.groups="drop")
write_csv(calibration,file.path(processed_dir,"attrition_calibration_deciles.csv"))
# Aggregate predictions only for Tableau; employee-level file stays under ignored data/processed.
local_predictions <- tibble(employee_id=test_df$employee_id,observed_class=as.character(truth_test),
                            predicted_class=as.character(pred_test),predicted_probability=as.numeric(prob_test))
write_csv(local_predictions,file.path(processed_dir,"attrition_predictions_local.csv"))

# Coefficients/odds ratios from the final logistic model, with Wald confidence intervals.
coef_tab <- broom::tidy(attrition_fit$finalModel,conf.int=TRUE,exponentiate=TRUE) %>%
  rename(odds_ratio=estimate,odds_ratio_ci_low=conf.low,odds_ratio_ci_high=conf.high) %>%
  mutate(model_note="Associational retrospective classifier; not a causal effect")
write_csv(coef_tab,file.path(processed_dir,"attrition_odds_ratios.csv"))

# Department-level dashboard aggregate: suppress groups under n=30; never export individual risk rankings.
aggregate_predictions <- hr %>% select(employee_id,department_name,resigned) %>%
  inner_join(local_predictions,by="employee_id") %>% group_by(department_name) %>%
  summarise(employee_count=n(),observed_resignation_proportion=mean(resigned),
            mean_predicted_resignation_probability=mean(predicted_probability),
            .groups="drop") %>% filter(employee_count>=30)
write_csv(aggregate_predictions,file.path(processed_dir,"attrition_model_department_aggregate.csv"))

# ---------------- Model 2: adjusted compensation/pay-equity analysis ----------------
# Gender is used only in this aggregate audit; model outputs are not individual salary recommendations.
pay <- hr %>% filter(is.finite(monthly_salary),!is.na(gender),!is.na(job_title),!is.na(department_name),
                     !is.na(education_level),!is.na(years_at_company),!is.na(performance_score)) %>%
  mutate(gender=factor(gender),job_title=factor(job_title),department_name=factor(department_name),education_level=factor(education_level))
if(nrow(pay)<100) stop("Too few complete salary records for the planned adjusted analysis.")
gender_summary <- pay %>% group_by(gender) %>% summarise(employee_count=n(),mean_salary=mean(monthly_salary),
  median_salary=median(monthly_salary),.groups="drop") %>% mutate(suppressed=employee_count<30,
  mean_salary=if_else(suppressed,NA_real_,mean_salary),median_salary=if_else(suppressed,NA_real_,median_salary))
write_csv(gender_summary,file.path(processed_dir,"pay_gap_unadjusted_by_gender.csv"))

levels_gender <- levels(pay$gender)
male_level <- levels_gender[tolower(levels_gender)=="male"]
reference_gender <- if(length(male_level)) male_level[[1]] else levels_gender[[1]]
pay$gender <- relevel(pay$gender,ref=reference_gender)
# If salary is strictly positive and log transform reduces absolute skew, use log salary.
skew <- function(x) { m<-mean(x); s<-sd(x); if(!is.finite(s)||s==0) return(0); mean((x-m)^3)/(s^3) }
use_log_salary <- all(pay$monthly_salary>0) && abs(skew(log(pay$monthly_salary)))<abs(skew(pay$monthly_salary))
pay$response_salary <- if(use_log_salary) log(pay$monthly_salary) else pay$monthly_salary
response_name <- if(use_log_salary) "log(Monthly_Salary)" else "Monthly_Salary"
pay_formula <- response_salary ~ gender + job_title + department_name + years_at_company + education_level + performance_score
set.seed(4301)
pay_train_idx <- createDataPartition(pay$monthly_salary,p=.80,list=FALSE)
pay_train <- pay[pay_train_idx,,drop=FALSE]
pay_test <- pay[-pay_train_idx,,drop=FALSE]
pay_fit_test <- lm(pay_formula,data=pay_train)
pay_prediction <- predict(pay_fit_test,newdata=pay_test)
observed_salary <- pay_test$monthly_salary
predicted_salary <- if(use_log_salary) exp(pay_prediction) else pay_prediction
pay_rmse <- sqrt(mean((observed_salary-predicted_salary)^2))
pay_mae <- mean(abs(observed_salary-predicted_salary))
# Inferential fit on all observed rows; coefficients are conditional associations, not causal effects.
pay_fit <- lm(pay_formula,data=pay)
pay_tidy <- broom::tidy(pay_fit,conf.int=TRUE)
if(use_log_salary) {
  pay_tidy <- pay_tidy %>% mutate(adjusted_percent_difference=(exp(estimate)-1)*100,
    adjusted_percent_ci_low=(exp(conf.low)-1)*100,adjusted_percent_ci_high=(exp(conf.high)-1)*100)
}
pay_tidy <- pay_tidy %>% mutate(reference_gender=reference_gender,model_scale=ifelse(use_log_salary,"log salary","salary units"),
  interpretation="Conditional association; not proof of discrimination or a salary recommendation")
write_csv(pay_tidy,file.path(processed_dir,"pay_equity_adjusted_coefficients.csv"))

# Targeted unadjusted female-vs-male comparison when both are present; minimum group n=30.
female_level <- levels_gender[tolower(levels_gender)=="female"]
if(length(male_level)>0 && length(female_level)>0) {
  m <- pay %>% filter(as.character(gender)==male_level[[1]]) %>% summarise(n=n(),mean=mean(monthly_salary),median=median(monthly_salary))
  f <- pay %>% filter(as.character(gender)==female_level[[1]]) %>% summarise(n=n(),mean=mean(monthly_salary),median=median(monthly_salary))
  gap <- tibble(reference_group=male_level[[1]],comparison_group=female_level[[1]],reference_n=m$n,comparison_n=f$n,
    unadjusted_mean_gap_percent=if(m$n>=30&&f$n>=30)(f$mean-m$mean)/m$mean*100 else NA_real_,
    unadjusted_median_gap_percent=if(m$n>=30&&f$n>=30)(f$median-m$median)/m$median*100 else NA_real_,
    minimum_group_n=30,suppressed=m$n<30||f$n<30)
} else {
  gap <- tibble(reference_group=reference_gender,comparison_group="No Female/Male pair in source categories",
    reference_n=NA_integer_,comparison_n=NA_integer_,unadjusted_mean_gap_percent=NA_real_,
    unadjusted_median_gap_percent=NA_real_,minimum_group_n=30,suppressed=TRUE)
}
write_csv(gap,file.path(processed_dir,"pay_gap_female_vs_male.csv"))
pay_metrics <- tibble(model="Multiple linear regression: salary on gender, role, department, tenure, education, performance",
  rows=nrow(pay),response=response_name,
  gender_reference=reference_gender,r_squared=summary(pay_fit)$r.squared,adjusted_r_squared=summary(pay_fit)$adj.r.squared,
  holdout_rmse=pay_rmse,holdout_mae=pay_mae,holdout_n=nrow(pay_test),
  interpretation_limit="Source currency and predictor timing are undocumented; conditional association only")
write_csv(pay_metrics,file.path(processed_dir,"pay_equity_model_metrics.csv"))

# VIF/GVIF diagnostics. car reports GVIF for multi-level factors; adjusted GVIF is comparable.
vif_result <- tryCatch(car::vif(pay_fit),error=function(e) e)
if(inherits(vif_result,"error")) {
  vif_table <- tibble(term="VIF computation",value=NA_real_,note=conditionMessage(vif_result))
} else if(is.matrix(vif_result)) {
  vif_table <- as.data.frame(vif_result) %>% tibble::rownames_to_column("term") %>%
    mutate(adjusted_gvif=GVIF^(1/(2*Df)),note="car::vif generalized VIF")
} else {
  vif_table <- tibble(term=names(vif_result),value=as.numeric(vif_result),note="car::vif")
}
write_csv(vif_table,file.path(processed_dir,"pay_equity_vif.csv"))

p_gap <- gender_summary %>% filter(!suppressed) %>% ggplot(aes(gender,median_salary,fill=gender))+geom_col(show.legend=FALSE)+
  labs(title="Unadjusted median salary by gender",subtitle="Aggregate descriptive comparison; role mix is not controlled",x="Gender category",y="Median salary (dataset units)")+theme_minimal()
ggsave(file.path(out_dir,"unadjusted_median_salary_by_gender.png"),p_gap,width=8,height=5,dpi=220)
p_pay_pred <- tibble(observed=observed_salary,predicted=predicted_salary) %>% ggplot(aes(observed,predicted))+
  geom_point(alpha=.3,color="#246B8E")+geom_abline(slope=1,intercept=0,linetype=2,color="#C67D32")+
  labs(title="Held-out compensation model: observed vs predicted",x="Observed monthly salary (dataset units)",y="Predicted monthly salary (dataset units)")+theme_minimal()
ggsave(file.path(out_dir,"pay_model_observed_vs_predicted.png"),p_pay_pred,width=7,height=6,dpi=220)
p_resid <- tibble(fitted=fitted(pay_fit),residuals=residuals(pay_fit)) %>% ggplot(aes(fitted,residuals))+
  geom_point(alpha=.22,color="#246B8E")+geom_hline(yintercept=0,linetype=2)+
  labs(title="Compensation model residuals vs fitted",x="Fitted response",y="Residual")+theme_minimal()
ggsave(file.path(out_dir,"pay_model_residuals.png"),p_resid,width=7,height=5,dpi=220)
qq <- tibble(sample=residuals(pay_fit)) %>% ggplot(aes(sample=sample))+stat_qq(alpha=.35)+stat_qq_line(color="#C67D32")+
  labs(title="Compensation model residual Q-Q plot",x="Theoretical quantiles",y="Sample quantiles")+theme_minimal()
ggsave(file.path(out_dir,"pay_model_qq.png"),qq,width=7,height=5,dpi=220)

cat("Attrition model: ROC-AUC=",round(roc_auc,4),", PR-AUC=",round(pr_area,4),", threshold=",round(selected_threshold,3),"\n",sep="")
cat("Pay model: adjusted R-squared=",round(summary(pay_fit)$adj.r.squared,4),", holdout RMSE=",round(pay_rmse,3),"\n",sep="")
cat("Employee-level predictions remain local in ignored data/processed; only aggregates should be connected to Tableau Public.\n")
