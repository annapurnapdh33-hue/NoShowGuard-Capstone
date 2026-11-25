### **GitHub repository link :** https://github.com/annapurnapdh33-hue/NoShowGuard-Capstone.git
# CareLoop Clinics — No-Show Guard Project

## 1. Project Summary
* **Part 1 (Data Foundations):** Ingested 1,020 raw appointment bookings, rejecting 32 malformed records during initial parsing and yielding 990 clean rows after removing 20 exact duplicates, 6 unreadable dates, and 4 missing statuses, establishing an overall baseline no-show rate of 22.0% (218 out of 990 appointments).
* **Part 2 (SQL Database Analytics):** Across 8 outpatient clinics in 6 Indian cities, clinic-level no-show rates ranged from 13.8% (Vaishali Nagar Care Clinic) to 33.3% (Gomti Nagar Care Point), while booking lead times of 31+ days suffered a 60.5% no-show rate compared to just 16.2% for lead times of 1–7 days.
* **Part 3 (Machine Learning Risk Model):** Evaluated predictive models on 792 training rows using 5-fold cross-validation; Logistic Regression achieved the highest cross-validated ROC-AUC (0.77) over Decision Trees (0.68) and Random Forests (0.75), achieving an evaluation ROC-AUC of ~0.79 and a 0.57 recall rate on 198 test rows at an optimized risk threshold of 0.35.
* **Part 4 (GenAI Call-Centre Note Classification):** Processed 10 follow-up call-centre notes using Gemini Flash with Pydantic validation (1 blank note skipped); text reasoning extracted `forgot_or_no_reminder` as a major root cause, where 100% of appointments classified under this cause (2 out of 2) had not received an automated reminder (`reminder_sent = No`).

---

## 2. Business Recommendation
CareLoop Clinics should immediately target long-lead bookings (>15 days) and clinics in high-risk locations (such as Gomti Nagar in Lucknow at 33.3% no-show rate and Hadapsar in Pune at 27.3%) by deploying pre-appointment phone calls on the evening prior to scheduled visits. Out of 990 analyzed appointments, 218 resulted in no-shows (22.0% overall rate), with no-show rates scaling drastically from 16.2% for 1–7 day lead times to 60.5% for appointments booked 31+ days in advance. Furthermore, Logistic Regression modeling reveals that sending appointment reminders reduces the odds of a no-show by approximately 69% (odds ratio ~0.31, holding other features constant). By deploying the predictive risk model at an optimized decision threshold of 0.35, front-desk staff can proactively identify and phone the top ~49 highest-risk patients each evening, reclaiming wasted doctor slots while optimizing staff call capacity.

---

## 3. Model Selection & Threshold Strategy
* **Model Selection:** Logistic Regression was selected as the optimal model based strictly on 5-fold cross-validated training ROC-AUC (0.77 vs. 0.68 for Decision Tree max_depth=3 and 0.75 for Random Forest). Unscaled features were passed via an `sklearn` Pipeline to ensure `StandardScaler` was fitted strictly inside each cross-validation fold without data leakage.
* **Decision Threshold:** The decision threshold was tuned on out-of-fold training probabilities, choosing **0.35** over the default 0.50 threshold because it improved the training F1-score from ~0.35 to ~0.49 and boosted recall from ~0.25 to ~0.47. In healthcare operations, a false negative (unflagged no-show) costs an empty doctor slot, whereas a false positive (unnecessary phone call) costs only ~1 minute of front-desk staff time. On the unseen test set (198 rows), the model at threshold 0.35 achieved **ROC-AUC ~0.79, precision ~0.57, and recall ~0.57**, flagging 49 high-risk bookings.

---

## 4. Analytical & Operational Limitations
1. **GenAI Sample Size:** The 10 analyzed call-centre notes serve as an illustrative proof-of-concept for automated structured extraction and cannot capture full clinic-wide root cause distributions across all 8 locations.
2. **Preprocessing Data Leakage:** Interquartile ranges (IQR), outlier fences, and medians in Task 1.3 were computed over the entire 990-row dataset before the train/test split, allowing test set row values slight indirect influence on data cleaning boundaries.
3. **Observational Association vs. Causation:** All statistical models are built on observational data; identified coefficients (such as the 69% odds reduction associated with reminders) represent statistical correlations rather than confirmed causal mechanisms.

---

## 5. Repository Deliverables
```text
├── 01_ingest_clean.ipynb      # Part 1: Python Ingestion, Validation & Cleaning (Tasks 1.1–1.6)
├── 02_queries.sql             # Part 2: SQL Table Creation, Ingestion & Analysis Queries
├── 03_model.ipynb             # Part 3: ML Feature Engineering, Modeling & GridSearchCV
├── 04_genai.ipynb             # Part 4: GenAI Gemini API Classification & Pydantic Checks
├── appointments_clean.csv     # Exported clean dataset (990 rows, 16 columns)
├── clinics_enriched.csv       # Enriched clinic data with Open-Meteo temperature values (8 rows)
├── load_data.sql              # Auto-generated SQL INSERT statements (998 rows)
├── notes_analysed.csv         # Structured GenAI classification results (10 rows)
├── rejected_rows.json         # Malformed JSON row dump from Task 1.1 (32 rows)
├── test_risk_scores.csv       # Test set risk probabilities and flags at threshold 0.35 (198 rows)
└── data/                      # Original unedited raw data pack
    ├── appointments.csv
    ├── clinics.csv
    └── followup_notes.csv
```
