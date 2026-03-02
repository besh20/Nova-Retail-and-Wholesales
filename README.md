# Nova-Retail-and-Wholesales
A Full Stack Data Analysis revolving around retail and wholesale around the world 

## Project Overview
This project's goal is was to move beyond simple "sales charts" and provide a deep dive into customer segments, return risks, and operational performance. This is my second major data project, focusing on handling real-world data issues like missing IDs, cancelled orders, and non-product fees.

## Phase 1: Data Engineering (MySQL)
The raw data was originally unformatted and contained several administrative "noise" items. I used SQL to clean and structure the data before it ever touched Power BI.

  ### Data Type Correction: 
  Converted string-based dates and times into proper DATE and TIME formats for time-series analysis.Handling
  
  ### Missing Values: 
  Identified that ~25% of CustomerID entries were missing. Instead of deleting them, I labeled them as 'Guest' to preserve the total revenue impact.
  
  ### Transaction Logic: 
  Created a TransactionStatus flag to separate 'Completed' sales from 'Cancelled' orders (identified by the "C" prefix in Invoice numbers).
  
  ### Item Classification: 
  Filtered out warehouse adjustments and "bad debt" while categorizing non-physical items like Vouchers and Postage Fees to avoid skewing product-only analysis.
  
  ### Feature Engineering: 
  Calculated a LineTotal column ($Quantity \times UnitPrice$) at the database level to optimize dashboard performance.

## Phase 2: Business Intelligence (Power BI)

I built a 3-page interactive dashboard designed for an executive audience, using a high-contrast "Dark Mode" theme for a modern, professional feel.

### 1. Executive Sales Overview
  Dynamic KPIs: Tracks Net Revenue, Total Orders, Return rate, and Average Order Value.
  
  Time Intelligence: Developed custom DAX measures to show Month-over-Month (MoM) growth with visual trend indicators (arrows).
  
  Segmentation: Engineered a "Sale Type" logic to split revenue between Wholesale (bulk orders of 20+ units) and Retail (individual consumers).

  Revenue bY Country: Calculated revenue according to country sales to identifyb which countries has the most income.

### 2. Product & Inventory Performance
  Outlier Detection: Used a Scatter Plot to identify high-revenue vs. high-volume products.
  
  Pareto Analysis: Discovered that a small fraction of products (Top 763) generate 80% of the total revenue.
  
  Peak Hour Analysis: Visualized order volume by time of day to identify the "Golden Hours" of shopping activity (12:00 PM peak).

### 3. Customer Behavior & Segments
  Whale Analysis: Identified the "Top Spenders" by filtering out guest data and ranking individual Customer IDs by total expenditure.
  
  Customer Distribution: Identified that a samll number of customer are the ones who are giving high income.

  Order Completion Rate
  
## Final Insights

  The Return Factor: While the completion rate is high (92%), returns are concentrated in specific high-value items, suggesting a quality control or "description match" opportunity.
  
  Wholesale Opportunity: Bulk buyers represent a significant revenue chunk; a loyalty program targeting these "Whales" could stabilize long-term growth.

## How to use this Repo
  SQL Script: Run the provided .sql file to create and clean the database.
  
  Screenshot: Open the Screenshot folder for a preview of what the project looks like 
  
  PBIX File: Open the Power BI file to explore the interactive visualizations
