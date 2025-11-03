# Olist-ECommerce-Analysis
"End-to-end analysis of Olist E-Commerce dataset. Identified key drivers of customer churn and provided data-driven recommendations."


# Olist E-Commerce Analysis: A Deep Dive into Customer Churn & Product Strategy

![Platform](https://img.shields.io/badge/Tools-SQL_|_Power_BI_|_Python-blue)
![Analysis](https://img.shields.io/badge/Analysis-RFM_|_NLP_|_Predictive-green)

---

### 1. Executive Summary: The 180° Twist

This project began as a routine analysis of the Olist E-Commerce dataset (95,000+ orders). Initial findings pointed to a **94% customer churn rate** (one-time buyers) driven primarily by **slow delivery times**.

However, a deeper analysis revealed a 180° twist: our initial hypothesis that high-revenue categories (`bed_bath_table`) were the problem was **wrong**. They were actually our "Stars".

The *real* problem was a "Problem Child" category (`office_furniture`) with high demand ($270K revenue) but a disastrous 3.72 review score. Further NLP analysis on 1-star reviews proved this was due to **damaged goods, wrong items, and poor quality**—not just delivery delays.

This project tells the story of how we used data to move from a flawed, general assumption to a precise, surgical recommendation that could save a $270K category and improve customer retention.

---

### 2. Key Business Questions

1.  **Customer Behavior:** Who are our customers and why are they leaving? (RFM)
2.  **Operations:** What is the *real* relationship between delivery performance and customer satisfaction?
3.  **Product:** Which product categories are our "Stars" 🌟, "Problems" 🤔, "Opportunities" 🚀, and "Dogs" 🐶?
4.  **Root Cause (NLP):** When customers complain (besides delivery), what are they *actually* complaining about?

---

### 3. Tools & Tech Stack

* **Data Storage & Retrieval:** SQL (PostgreSQL)
* **Data Visualization & Dashboarding:** Power BI (including DAX for RFM)
* **Text Analysis (NLP) & Modeling:** Python (Pandas, NLTK, Scikit-learn)
* **IDE:** Google Colab / Jupyter Notebook

---

### 4. The Analysis & Insights (The Data Story)

#### Analysis 1: The "Leaky Bucket" (RFM & Logistics)

* **Goal:** To segment customers and find the root cause of dissatisfaction.
* **Insight:** We have a "leaky bucket." **94% of our 95k customers are "One-Time Buyers"**. An RFM analysis classified 83K customers as "At Risk."
* **Root Cause:** A strong negative correlation was found between `delivery_time` and `review_score`. **Delivery delays were the #1 driver of customer churn.**

#### Analysis 2: The "Problem Child" (Product Portfolio Matrix)

* **Goal:** To find which *products* were driving bad reviews.
* **Insight:** The "Aha!" moment. We plotted all categories by Revenue vs. Avg. Review Score.
    * **Stars 🌟:** `bed_bath_table` ($1M revenue, 4.0 score) - Our high-performing cash cow.
    * **The *Real* Problem Child 🤔:** `office_furniture` ($270K revenue, 3.72 score) - This category had high demand but was failing miserably, poisoning a $270K revenue stream.
    * **Rising Star 🚀:** `fashion_childrns` (High score, low revenue) - An untapped opportunity.
    * **Dog 🐶:** `security_and_services` (Low score, low revenue) - A category to delist.

![Product Portfolio Matrix](PowerBI_Visuals/Products&sellers.png)

#### Analysis 3: The Voice of the Customer (NLP Root Cause)

* **Goal:** To understand *why* `office_furniture` had a 3.72 score.
* **Process:** We ran NLP Topic Modeling (LDA) on all 1-star reviews *after* filtering out delivery-related words (`atraso`, `demora`).
* **Insight:** The model revealed 4 key topics unrelated to delivery:
    1.  **Damaged/Broken Item** (`produto veio quebrado`)
    2.  **Wrong Item Sent** (`produto diferente foto`)
    3.  **Missing Parts/Items** (`comprei dois veio um`)
    4.  **Poor Quality** (`qualidade ruim material`)

This proved that the `office_furniture` problem was a **quality and fulfillment crisis**, not just a shipping one.

![NLP Word Cloud](Notebooks/NLP.png)

---

### 5. Strategic Recommendations (The Action Plan)

Based on the full analysis, I presented a 5-point strategic plan:

1.  **[Commercial] Surgical Strike on `office_furniture`:**
    * **Action:** Immediately audit all sellers in this category. Impose new packaging and quality standards. Suspend non-compliant sellers.
    * **Goal:** Fix the 3.72 score and save the $270K revenue stream.

2.  **[Commercial] Protect & Clean our "Stars":**
    * **Action:** Use NLP insights to "clean" the `bed_bath_table` category by removing the few bad sellers sending damaged goods.
    * **Goal:** Protect our $1M revenue stream and raise its score from 4.0 to 4.2.

3.  **[Operations] Launch "Seller Quality Scorecard":**
    * **Action:** Create an internal dashboard (the one we built) to score sellers based on `delivery_time`, `NLP_complaint_rate`, and `order_accuracy`.
    * **Goal:** Automate the process of flagging bad sellers.

4.  **[Marketing] Targeted Campaigns:**
    * **"At Risk" Segment:** Launch a re-activation campaign acknowledging past issues ("We've improved our shipping & quality") with a discount.
    * **"Rising Stars":** Heavily market the `fashion_childrns` category.

5.  **[Commercial] Delist the "Dogs":**
    * **Action:** Immediately delist the `security_and_services` category.
    * **Goal:** Stop wasting resources and protect the brand's reputation.

---

### Project Structure
Olist-ECommerce-Analysis/ │ ├── SQL/ │ ├── 1_Logistics_and_Reviews.sql │ ├── 2_RFM_Customer_Segmentation.sql │ ├── 3_Product_Portfolio_Analysis.sql │ └── 4_NLP_Data_Export.sql │ ├── Notebooks/ │ └── Olist_NLP_Topic_Modeling.ipynb │ ├── PowerBI_Visuals/ │ ├── Customersegmentations.png  │ ├── Deliveryperformance.png  │ ├── Month Growth.png  │ ├── Products&sellers.png  │ └── NLP_WordCloud.png  │ └── README.md

---

### Contact

Mohamed Shauky
* [LinkedIn](https://www.linkedin.com/in/mohamed-shauky-7208a0303/)
* [Portfolio](https://mohamedshauky.my.canva.site/)
