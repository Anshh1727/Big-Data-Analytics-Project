# SQL verification evidence

`sql_verification.txt` is captured output from the completed PostgreSQL verification query against the supplied synthetic dataset in an isolated local database. It reports source/clean row counts of 100,000; zero duplicate employee IDs; zero missing values for all 20 source columns; zero invalid date/range checks; 100,000 loaded employee and ABT rows; complete one-to-one workforce, performance and compensation coverage; and zero row-count, resignation, salary-total or department reconciliation differences.

This is authentic terminal text evidence rather than a screenshot. Raw input, row-level employee exports, predictions and the local database are excluded from Git.
