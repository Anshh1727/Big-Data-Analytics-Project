#!/usr/bin/env Rscript
args_all <- commandArgs(trailingOnly=FALSE)
file_arg <- grep("^--file=",args_all,value=TRUE)
script_path <- if(length(file_arg)) sub("^--file=","",file_arg[[1]]) else "scripts/install_r_packages.R"
project_root <- normalizePath(file.path(dirname(script_path),".."),mustWork=TRUE)
lib <- file.path(project_root,"r_lib")
dir.create(lib,recursive=TRUE,showWarnings=FALSE)
.libPaths(c(lib,.libPaths()))
required <- c("dplyr","ggplot2","readr","tidyr","DBI","RPostgres","caret","pROC","broom","car")
missing <- required[!vapply(required,requireNamespace,logical(1),quietly=TRUE)]
if(length(missing)) {
  install.packages(missing,lib=lib,repos="https://cloud.r-project.org",dependencies=NA)
}
remaining <- required[!vapply(required,requireNamespace,logical(1),quietly=TRUE)]
if(length(remaining)) stop("Packages still missing from project library: ",paste(remaining,collapse=", "))
cat("Project-local R library ready at ",lib,"\n",sep="")
