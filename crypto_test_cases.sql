USE `Crypto`;

-- =================================================================================
-- A) ROLE‐BASED VIEWS (Doctors vs. Nurses)
-- =================================================================================
-- dynamically grab one doctor & one nurse
SET @doc   = (SELECT user_id FROM doctors  LIMIT 1);
SET @nurse = (SELECT user_id FROM nurses   LIMIT 1);

SELECT COUNT(*) AS is_doc
  FROM `doctors`
 WHERE user_id = @doc;
-- EXPECT 1

SELECT COUNT(*) AS is_nurse
  FROM `nurses`
 WHERE user_id = @nurse;
-- EXPECT 1


-- =================================================================================
-- B) PATIENTS: ENCRYPTION, VIEW & SOFT DELETE
-- =================================================================================
-- dynamically pick an undeleted patient
SET @pid = (
  SELECT patient_id 
    FROM patients 
   WHERE is_deleted = FALSE 
   LIMIT 1
);

-- 1) Show raw encrypted address columns
SELECT
    HEX(address_line1) AS enc_line1,
    HEX(address_line2) AS enc_line2
  FROM patients
 WHERE patient_id = @pid;

-- 2) Decrypt via view
SELECT
    patient_id, first_name, last_name,
    address_line1, address_line2,
    city, state, postal_code, country
  FROM vw_patients
 WHERE patient_id = @pid;

-- 3) Soft-delete & confirm it’s hidden
UPDATE patients 
   SET is_deleted = TRUE 
 WHERE patient_id = @pid;

SELECT COUNT(*) AS still_visible
  FROM vw_patients
 WHERE patient_id = @pid;
-- EXPECT 0


-- =================================================================================
-- C) MEDICAL_RECORDS: FULLTEXT, VERSIONING & HISTORY
-- =================================================================================
-- dynamically re-pick an active patient & doctor
SET @pid = (SELECT patient_id FROM patients LIMIT 1);
SET @doc = (SELECT user_id    FROM doctors  LIMIT 1);

-- 1) Insert
INSERT INTO medical_records
  (patient_id, created_by, record_type, record_date, description)
VALUES
  (@pid,@doc,'Doctor Note','2025-05-01','Initial test note');
SET @rec = LAST_INSERT_ID();

-- 2) Full-text search
SELECT record_id
  FROM medical_records
 WHERE MATCH(description_plain) AGAINST('Initial');

-- 3) Update → bump version + archive old
UPDATE medical_records
   SET description = 'Follow-up test note'
 WHERE record_id = @rec;

SELECT version
  FROM medical_records 
 WHERE record_id = @rec;
-- EXPECT display "version" = 2

SELECT COUNT(*) AS hist1
  FROM medical_records_history
 WHERE record_id = @rec;
-- EXPECT display "hist1" = 1

-- 4) Delete → history++
DELETE FROM medical_records 
 WHERE record_id = @rec;

SELECT COUNT(*) AS hist2
  FROM medical_records_history
 WHERE record_id = @rec;
-- EXPECT display "hist2" = 2


-- =================================================================================
-- D) VITALS: GENERATED BMI, FULLTEXT & HISTORY
-- =================================================================================
SET @pid   = (SELECT patient_id FROM patients LIMIT 1);
SET @nurse = (SELECT user_id    FROM nurses   LIMIT 1);

-- 1) Insert
INSERT INTO vitals
  (patient_id, measured_by, measurement_datetime,
   blood_pressure_systolic, blood_pressure_diastolic,
   heart_rate, respiratory_rate, temperature,
   oxygen_saturation, weight, height, notes)
VALUES
  (@pid,@nurse,NOW(),
   120,80,  70,16,36.6,
   98, 160,65,'Baseline exam');
SET @vid = LAST_INSERT_ID();

-- 2) Full-text search on notes
SELECT vital_id
  FROM vitals
 WHERE MATCH(notes) AGAINST('Baseline');

-- 3) Check generated BMI
SELECT weight, height, bmi
  FROM vitals
 WHERE vital_id = @vid;
-- EXPECT display "bmi" ≃ 26.6

-- 4) Update → history
UPDATE vitals
   SET heart_rate = 75
 WHERE vital_id = @vid;

SELECT COUNT(*) AS vh1
  FROM vitals_history
 WHERE vital_id = @vid;
-- EXPECT display "vh1" = 1

-- 5) Delete → history++
DELETE FROM vitals
 WHERE vital_id = @vid;

SELECT COUNT(*) AS vh2
  FROM vitals_history
 WHERE vital_id = @vid;
-- EXPECT display "vh2" = 2


-- =================================================================================
-- E) APPOINTMENTS: CRUD & FULLTEXT
-- =================================================================================
SET @pid = (SELECT patient_id FROM patients LIMIT 1);
SET @doc = (SELECT user_id    FROM doctors  LIMIT 1);

-- 1) Schedule
INSERT INTO appointments
  (patient_id, staff_id, appointment_datetime,
   duration_minutes, status, location, reason, notes)
VALUES
  (@pid,@doc,'2025-06-01 11:00:00',45,
   'Scheduled','Rm 301','Checkup','Review test results');
SET @aid = LAST_INSERT_ID();

-- 2) Full-text search
SELECT appointment_id
  FROM appointments
 WHERE MATCH(notes) AGAINST('results');
-- EXPECT display on "appoinment_id" 


-- =================================================================================
-- F) LAB_RESULTS: STRUCTURED INSERT & CASCADE
-- =================================================================================
SET @pid = (SELECT patient_id FROM patients LIMIT 1);
SET @doc = (SELECT user_id    FROM doctors  LIMIT 1);

-- 1) Create lab record
INSERT INTO medical_records
  (patient_id, created_by, record_type, record_date, description)
VALUES
  (@pid,@doc,'Lab Report','2025-05-15','Routine labs');
SET @labr = LAST_INSERT_ID();

-- 2) Insert lab result
INSERT INTO lab_results
  (record_id, test_name, test_value, test_units, performed_at)
VALUES
  (@labr,'Hemoglobin',13.8,'g/dL','2025-05-15');

SELECT *
  FROM lab_results
 WHERE record_id = @labr;
-- EXPECT display show 1 row of data

-- 3) Cascade on delete
DELETE FROM medical_records 
 WHERE record_id = @labr;

SELECT COUNT(*) AS lr_left
  FROM lab_results
 WHERE record_id = @labr;
-- EXPECT display "lr_left" = 0


-- =================================================================================
-- G) IMAGING_SCANS: ENCRYPTION, VIEW & CASCADE
-- =================================================================================
SET @pid = (SELECT patient_id FROM patients LIMIT 1);
SET @doc = (SELECT user_id    FROM doctors  LIMIT 1);

-- 1) Imaging record
INSERT INTO medical_records
  (patient_id, created_by, record_type, record_date, description)
VALUES
  (@pid,@doc,'Imaging','2025-05-16','Chest X-Ray');
SET @imgr = LAST_INSERT_ID();

-- 2) Insert scan
INSERT INTO imaging_scans
  (record_id, modality, body_part, scan_date, file_path)
VALUES
  (@imgr,'X-Ray','Chest','2025-05-16','/tmp/xray001.dcm');

-- 3) Decrypt via view
SELECT *
  FROM vw_imaging_scans
 WHERE record_id = @imgr;
-- EXPECT display 1 row of data where "file_path = '/tmp/xray001.dcm'"

-- 4) Cascade delete
DELETE FROM medical_records 
 WHERE record_id = @imgr;

SELECT COUNT(*) AS is_left
  FROM imaging_scans
 WHERE record_id = @imgr;
-- EXPECT display "is_left" = 0


-- =================================================================================
-- H) DEPARTMENTS & ASSIGNMENTS
-- =================================================================================
-- pick one user & one patient
SET @doc = (SELECT user_id    FROM doctors  LIMIT 1);
SET @pid = (SELECT patient_id FROM patients LIMIT 1);

-- verify they’re already assigned by dummy-data
SELECT d.department_name
  FROM user_departments ud
  JOIN departments d ON ud.department_id = d.department_id
 WHERE ud.user_id = @doc;
-- EXPECT display "department_name" = where they are assigned

SELECT d.department_name
  FROM patient_departments pd
  JOIN departments d ON pd.department_id = d.department_id
 WHERE pd.patient_id = @pid;
-- EXPECT display "department_name" = where they are assigned


-- =================================================================================
-- I) BACKUP & RECOVERY EVENTS
-- =================================================================================
-- just check event existence
SHOW EVENTS 
 WHERE name LIKE 'ev_backup_%';

-- manual snapshot test
TRUNCATE TABLE patients_backup;
INSERT INTO patients_backup SELECT * FROM patients;
SELECT COUNT(*) AS snap_patients FROM patients_backup;

TRUNCATE TABLE medical_records_backup;
INSERT INTO medical_records_backup SELECT * FROM medical_records;
SELECT COUNT(*) AS snap_records FROM medical_records_backup;

TRUNCATE TABLE vitals_backup;
INSERT INTO vitals_backup SELECT * FROM vitals;
SELECT COUNT(*) AS snap_vitals FROM vitals_backup;

TRUNCATE TABLE appointments_backup;
INSERT INTO appointments_backup SELECT * FROM appointments;
SELECT COUNT(*) AS snap_appts FROM appointments_backup;

TRUNCATE TABLE lab_results_backup;
INSERT INTO lab_results_backup SELECT * FROM lab_results;
SELECT COUNT(*) AS snap_labs FROM lab_results_backup;

TRUNCATE TABLE imaging_scans_backup;
INSERT INTO imaging_scans_backup SELECT * FROM imaging_scans;
SELECT COUNT(*) AS snap_imgs FROM imaging_scans_backup;

-- End of suite. If each block returns the expected counts and no errors, you're all green!```

-- **How to run:**  
-- - In your SQL client, select **each lettered block** (A, B, C, …) and Execute.  
-- - Confirm the `EXPECT` comments match actual results.  
