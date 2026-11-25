CREATE DATABASE noshowguard; 
USE noshowguard;

CREATE TABLE clinics (
  clinic_id VARCHAR(5) PRIMARY KEY, clinic_name VARCHAR(40) NOT NULL, city VARCHAR(20) NOT NULL,
  tier VARCHAR(10), latitude DECIMAL(8,4), longitude DECIMAL(8,4), temp_c DECIMAL(5,1));
CREATE TABLE appointments (
  appointment_id VARCHAR(8) PRIMARY KEY, patient_id VARCHAR(8) NOT NULL, clinic_id VARCHAR(5) NOT NULL,
  booked_on DATE, appt_date DATE, age INT, gender VARCHAR(1), distance_km DECIMAL(5,1), fee_inr INT,
  booking_channel VARCHAR(10), visit_type VARCHAR(12), reminder_sent VARCHAR(3), prior_no_shows INT,
  status VARCHAR(10), lead_days INT, no_show INT,
  FOREIGN KEY (clinic_id) REFERENCES clinics(clinic_id));
  
SELECT COUNT(*) AS total_clinics
FROM clinics;

SELECT COUNT(*) AS total_appointments
FROM appointments;

SELECT SUM(no_show) AS total_no_shows
FROM appointments;

SELECT * FROM appointments WHERE appointment_id = 'A0001';

-- Task 2.1

INSERT INTO appointments VALUES (
            'A0001', 'P196', 'C05', '2025-01-22', '2025-02-03', 
            45, 'F', 12.5, 500, 'Online', 'Consultation', 'Yes', 0, 'No-Show', 12, 1
        );

-- Duplicate primary key test
-- Expected result: Error Code 1062
-- Actual error: Error Code: 1062. Duplicate entry 'A0001' for key 'appointments.PRIMARY'

-- Task 2.2

SELECT
c.clinic_name, 
c.city, 
COUNT(a.appointment_id) AS appointments, 
SUM(a.no_show) AS no_shows,
ROUND(100.0 * SUM(a.no_show) / COUNT(*), 1) AS no_show_pct 
FROM clinics c JOIN appointments a ON c.clinic_id = a.clinic_id
GROUP BY c.clinic_id, c.clinic_name, c.city 
HAVING COUNT(a.appointment_id) >= 95
ORDER BY no_show_pct DESC;

SELECT
c.clinic_name, 
c.city, 
COUNT(a.appointment_id) AS appointments, 
SUM(a.no_show) AS no_shows,
ROUND(100.0 * SUM(a.no_show) / COUNT(*), 1) AS no_show_pct 
FROM clinics c JOIN appointments a ON c.clinic_id = a.clinic_id
GROUP BY c.clinic_id, c.clinic_name, c.city 
ORDER BY no_show_pct DESC;

-- Task 2.2 Observation:
-- Gomti Nagar Care Point (Lucknow) has the highest
-- no-show rate of 33.3%, with 90 appointments.
-- It was excluded when HAVING COUNT(*) >= 95 was applied.

-- Task 2.3

SELECT 
    CASE 
        WHEN lead_days BETWEEN 1 AND 7 THEN '1-7'
        WHEN lead_days BETWEEN 8 AND 14 THEN '8-14'
        WHEN lead_days BETWEEN 15 AND 30 THEN '15-30'
        WHEN lead_days >= 31 THEN '31+'
        ELSE '0 or negative'
    END AS lead_time_band,
    COUNT(appointment_id) AS appointments,
    SUM(no_show) AS no_shows,
    ROUND(100.0 * SUM(no_show) / COUNT(*), 1) AS no_show_pct
FROM appointments
GROUP BY lead_time_band
ORDER BY MIN(lead_days);

-- Task 2.3 Observation:
-- The 31+ days lead-time group has the highest
-- no-show rate at 60.5% (26 out of 43 appointments).
-- The 1-7 days group has the lowest rate at 16.2%.

-- Task 2.4

WITH monthly AS (
	SELECT 
		SUBSTR(appt_date, 1, 7) AS months,
		COUNT(appointment_id) AS appointments,
		ROUND(100.0 * SUM(no_show) / COUNT(*), 1) AS no_show_pct
	FROM appointments
    GROUP BY months
)
SELECT
	months,
	appointments, 
	no_show_pct , 
	COALESCE(round(no_show_pct - lag(no_show_pct) OVER (ORDER BY months),1), '') 
	AS pct_point_change
FROM monthly;

-- Task 2.4 Observation:
-- February had the largest monthly decrease of 4.3 percentage points.
-- May had the largest increase of 2.8 percentage points.
-- June improved by 2.5 percentage points compared with May.

-- Task 2.5

WITH clinic_rates AS (
    SELECT 
        c.clinic_id,
        c.clinic_name,
        c.city,
        ROUND(100.0 * SUM(a.no_show) / COUNT(*), 1) AS no_show_pct
    FROM clinics c
    JOIN appointments a ON c.clinic_id = a.clinic_id
    GROUP BY c.clinic_id, c.clinic_name, c.city
),
overall_rate AS (
    SELECT 100.0 * SUM(no_show) / COUNT(*) AS avg_no_show_pct
    FROM appointments
)
SELECT 
    cr.city,
    cr.clinic_name,
    cr.no_show_pct,
    RANK() OVER (PARTITION BY cr.city ORDER BY cr.no_show_pct DESC) AS rank_in_city,
    CASE 
        WHEN cr.no_show_pct > o.avg_no_show_pct THEN 'above'
        WHEN cr.no_show_pct < o.avg_no_show_pct THEN 'below'
        ELSE 'equal'
    END AS vs_overall
FROM clinic_rates cr
CROSS JOIN overall_rate o
ORDER BY cr.city, rank_in_city;

-- Task 2.5 Observation:
-- Overall no-show rate is approximately 22.02%.
-- Gomti Nagar Care Point, Lucknow has the highest
-- clinic-level no-show rate at 33.3%.
-- Both Pune clinics are above the overall rate.