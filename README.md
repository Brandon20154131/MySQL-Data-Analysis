# MySQL-Data-Analysis
Data cleaning and exploratory analysis of global corporate layoffs using MySQL.
# Data Analytics Project

---
## 📖 Project Overview

This project focuses on cleaning, transforming and analysing a real-world dataset of global layoffs using MySQL. 
It is divided into two key phases:

**Data Cleaning**: Preparing raw data for analysis by handling duplicates, standardizing fields, and formatting dates.

**Exploratory Data Analysis (EDA)**: Running SQL-based queries to uncover patterns, trends, and insights in the layoffs data.




---
### 🧹 Data Cleaning Process

The data_cleaning.sql script ensures high-quality, analysis-ready data.

#### Key Steps:
- Create a staging table to preserve the raw dataset (best practice).
- Remove duplicates using window functions with ROW_NUMBER().
- Standardise text fields like company names, industries and countries.
- Convert and format date fields for time-series analysis.
- Handle NULL and blank values consistently.
- Remove irrelevant or incomplete rows and unnecessary columns.

#### Best Practices Applied:
- Always perform cleaning in a staging environment to protect raw data.
- Validate results after each transformation step.
- Use clear, well-documented SQL logic for reproducibility.

---
### 📊 Exploratory Data Analysis

The exploratory_analysis.sql script builds on the cleaned dataset (layoffs_staging2) to generate insights through SQL queries.

#### Analysis Highlights:
- **Aggregations**: Total layoffs by company, country, industry and year.
- **Rolling Totals**: Cumulative layoffs tracked month over month.
- **Ranking Queries**: Identify top companies and industries by layoff volume.
- **Outlier Detection (IQR Method)**: Flag abnormal layoffs by industry.
- **Layoff Classification**: Categorise events (e.g., Full , Large , Medium , Small).
- **Stored Procedure**: Parameterized query to analyse layoffs by country and industry dynamically.
- **Example**: CALL CountryIndustryBreakdown('United States', 5);

  Returns the top 5 industries with the most layoffs in the United States.

---
### 🧠 Insights Gained

Yearly and monthly trends in global layoffs.

Industries most affected by large-scale layoffs.

Top companies contributing to total layoffs over time.

Outlier detection helps identify unusual corporate downsizing events.

---
## 🧱 Tools & Technologies
- **Database**: MySQL 8.0+
- **Language**: SQL (CTEs, Window Functions, CASE statements)
- **Dataset**: layoffs.json (transformed into relational format)

Best Practices Followed
- **Work from raw → staging → cleaned layers.**
- **Document each transformation within scripts for transparency.**
- **Apply consistent naming conventions and clear code comments.**
- **Use parameterized procedures for flexible, reusable queries.**


## 📂 Repository Structure
```
MySQL-Data-Analysis/
│
├── data_cleaning.sql                 # Full SQL script for data cleaning & preprocessing
├── exploratory_analysis.sql          # SQL script containing analytical and summary queries
├── layoffs.json                      # Original dataset (raw source data)
│
└── README.md                         # Project overview and instructions 
```
