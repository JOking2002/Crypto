-- ============================================================================
-- dummy_data_tidy.sql
-- Description:
--   This script populates the `Crypto` database with realistic dummy data for
--   departments, users, patients, and transactional tables. It uses CTEs,
--   temporary tables, and cross-joins to generate large result sets efficiently.
-- Usage:
--   1. Ensure the `Crypto` database exists and use it: `USE Crypto;`
--   2. Execute this script in phpMyAdmin or MySQL Workbench.
--   3. All operations are idempotent or guarded by IF NOT EXISTS / IGNORE.
-- ============================================================================

-- Step 0: Set context to the Crypto database
USE `Crypto`;

-- ============================================================================
-- 0) Helper: Generate sequence 1..1000 via cross-join of digits (0..9)
--    We will reuse this `seq` temporary table in subsequent inserts.
-- ============================================================================

-- Drop any existing helper tables to avoid conflicts
DROP TEMPORARY TABLE IF EXISTS `digits`;
DROP TEMPORARY TABLE IF EXISTS `seq`;

-- Create `digits` (0 through 9)
CREATE TEMPORARY TABLE `digits` (
  `d` TINYINT PRIMARY KEY  -- single digit
) ENGINE=MEMORY;
INSERT INTO `digits` (`d`) VALUES
  (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

-- Create `seq` by combining hundreds, tens, and units digits
CREATE TEMPORARY TABLE `seq` AS
SELECT (h.d*100 + t.d*10 + u.d + 1) AS `n`
  FROM `digits` AS h
  CROSS JOIN `digits` AS t
  CROSS JOIN `digits` AS u
 WHERE (h.d*100 + t.d*10 + u.d + 1) <= 1000;

-- ============================================================================
-- 1) DEPARTMENTS: Insert 16 common hospital departments
--    Columns: department_name, ward, location, description
-- ============================================================================
INSERT IGNORE INTO `departments` (
  `department_name`,
  `ward`,
  `location`,
  `description`
) VALUES
  ('Cardiology','Ward A','Building 1','Heart & vessel care'),
  ('Radiology','Imaging Wing','Building 2','X-Ray, MRI, CT scans'),
  ('Oncology','Ward B','Building 3','Cancer treatment'),
  ('Emergency','ER','Building 1','Acute & urgent care'),
  ('Pediatrics','Ward C','Building 2','Child health'),
  ('Neurology','Ward D','Building 4','Brain & nervous system'),
  ('Orthopedics','Ward E','Building 1','Bones & joints'),
  ('Pathology','Lab','Building 3','Lab tests & biopsies'),
  ('Dermatology','Ward F','Building 2','Skin conditions'),
  ('Psychiatry','Ward G','Building 4','Mental health'),
  ('Urology','Ward H','Building 1','Urinary tract'),
  ('Nephrology','Ward I','Building 3','Kidney care'),
  ('Gastroenterology','Ward J','Building 2','Digestive system'),
  ('Intensive Care Unit','ICU','Building 1','Critical care'),
  ('Maternity','Ward K','Building 4','Mother & newborn care'),
  ('Ophthalmology','Ward L','Building 2','Eye care');

-- ============================================================================
-- 2) Name generation: Build pools of 100 first names and last names
--    Then cross-join to form 10,000 unique combos.
-- ============================================================================
-- Drop any existing helper tables to avoid conflicts
DROP TEMPORARY TABLE IF EXISTS `first_names`;
DROP TEMPORARY TABLE IF EXISTS `last_names`;
DROP TEMPORARY TABLE IF EXISTS `combos`;

-- Create and populate first_names
CREATE TEMPORARY TABLE `first_names` (
  `id` INT PRIMARY KEY,
  `name` VARCHAR(50) NOT NULL
) ENGINE=MEMORY;
INSERT INTO `first_names` (id,name) VALUES
  (1,'Liam'),(2,'Noah'),(3,'Oliver'),(4,'Elijah'),
  (5,'William'),(6,'James'),(7,'Benjamin'),(8,'Lucas'),
  (9,'Henry'),(10,'Alexander'),(11,'Mason'),(12,'Michael'),
  (13,'Ethan'),(14,'Daniel'),(15,'Jacob'),(16,'Logan'),
  (17,'Jackson'),(18,'Levi'),(19,'Sebastian'),(20,'Mateo'),
  (21,'Jack'),(22,'Owen'),(23,'Theodore'),(24,'Aiden'),
  (25,'Samuel'),(26,'Joseph'),(27,'John'),(28,'David'),
  (29,'Wyatt'),(30,'Matthew'),(31,'Luke'),(32,'Asher'),
  (33,'Carter'),(34,'Julian'),(35,'Grayson'),(36,'Leo'),
  (37,'Jayden'),(38,'Gabriel'),(39,'Isaac'),(40,'Lincoln'),
  (41,'Anthony'),(42,'Hudson'),(43,'Dylan'),(44,'Ezra'),
  (45,'Thomas'),(46,'Charles'),(47,'Christopher'),(48,'Jaxon'),
  (49,'Maverick'),(50,'Josiah'),(51,'Isaiah'),(52,'Andrew'),
  (53,'Elias'),(54,'Joshua'),(55,'Nathan'),(56,'Caleb'),
  (57,'Ryan'),(58,'Adrian'),(59,'Miles'),(60,'Eli'),
  (61,'Nolan'),(62,'Christian'),(63,'Aaron'),(64,'Cameron'),
  (65,'Ezekiel'),(66,'Colton'),(67,'Luca'),(68,'Landon'),
  (69,'Hunter'),(70,'Jonathan'),(71,'Santiago'),(72,'Axel'),
  (73,'Easton'),(74,'Cooper'),(75,'Jeremiah'),(76,'Angel'),
  (77,'Roman'),(78,'Connor'),(79,'Jameson'),(80,'Robert'),
  (81,'Greyson'),(82,'Jordan'),(83,'Ian'),(84,'Carson'),
  (85,'Jaxson'),(86,'Leonardo'),(87,'Nicholas'),(88,'Dominic'),
  (89,'Austin'),(90,'Evan'),(91,'Parker'),(92,'Wesley'),
  (93,'Kai'),(94,'Weston'),(95,'Declan'),(96,'Silas'),
  (97,'Rowan'),(98,'Chase'),(99,'Ryder'),(100,'Beckham');

-- Create and populate last_names
CREATE TEMPORARY TABLE `last_names` (
  `id` INT PRIMARY KEY,
  `name` VARCHAR(50) NOT NULL
) ENGINE=MEMORY;
INSERT INTO `last_names` (id,name) VALUES
  (1,'Smith'),(2,'Johnson'),(3,'Williams'),(4,'Brown'),
  (5,'Jones'),(6,'Garcia'),(7,'Miller'),(8,'Davis'),
  (9,'Rodriguez'),(10,'Martinez'),(11,'Hernandez'),(12,'Lopez'),
  (13,'Gonzalez'),(14,'Wilson'),(15,'Anderson'),(16,'Taylor'),
  (17,'Thomas'),(18,'Moore'),(19,'Jackson'),(20,'Martin'),
  (21,'Lee'),(22,'Perez'),(23,'Thompson'),(24,'White'),
  (25,'Harris'),(26,'Sanchez'),(27,'Clark'),(28,'Ramirez'),
  (29,'Lewis'),(30,'Robinson'),(31,'Walker'),(32,'Young'),
  (33,'Allen'),(34,'King'),(35,'Wright'),(36,'Scott'),
  (37,'Torres'),(38,'Nguyen'),(39,'Hill'),(40,'Flores'),
  (41,'Green'),(42,'Adams'),(43,'Nelson'),(44,'Baker'),
  (45,'Hall'),(46,'Rivera'),(47,'Campbell'),(48,'Mitchell'),
  (49,'Carter'),(50,'Roberts'),(51,'Gomez'),(52,'Phillips'),
  (53,'Evans'),(54,'Turner'),(55,'Diaz'),(56,'Parker'),
  (57,'Cruz'),(58,'Edwards'),(59,'Collins'),(60,'Reyes'),
  (61,'Stewart'),(62,'Morris'),(63,'Morales'),(64,'Murphy'),
  (65,'Cook'),(66,'Rogers'),(67,'Gutierrez'),(68,'Ortiz'),
  (69,'Morgan'),(70,'Cooper'),(71,'Peterson'),(72,'Bailey'),
  (73,'Reed'),(74,'Kelly'),(75,'Howard'),(76,'Ramos'),
  (77,'Kim'),(78,'Cox'),(79,'Ward'),(80,'Richardson'),
  (81,'Watson'),(82,'Brooks'),(83,'Chavez'),(84,'Wood'),
  (85,'James'),(86,'Bennett'),(87,'Gray'),(88,'Mendoza'),
  (89,'Ruiz'),(90,'Hughes'),(91,'Price'),(92,'Alvarez'),
  (93,'Castillo'),(94,'Sanders'),(95,'Patel'),(96,'Myers'),
  (97,'Long'),(98,'Ross'),(99,'Foster'),(100,'Morgan');

-- Create all first+last combos (10,000)
CREATE TEMPORARY TABLE `combos` ENGINE=MEMORY AS
SELECT
  ((fn.id-1)*100 + ln.id) AS `combo_id`,  -- unique combo 1–10000
  fn.name             AS `first_name`,
  ln.name             AS `last_name`
FROM `first_names` AS fn
CROSS JOIN `last_names`  AS ln;

-- ============================================================================
-- 3) USERS: Populate 1000 users using combos 1–1000
--    Columns: username, password_hash, password_salt, status, first_name, last_name,
--             email, phone
-- ============================================================================
INSERT INTO `users` (
  `username`,
  `password_hash`,
  `password_salt`,
  `status`,
  `first_name`,
  `last_name`,
  `email`,
  `phone`
)
SELECT
  -- username=`firstname.lastname####` lowercase
  LOWER(CONCAT(c.first_name,'.',c.last_name,LPAD(s.n,4,'0'))),
  -- password hash & salt derive from seq n
  UNHEX(SHA2(CONCAT('P@ss!',s.n),256)),
  UNHEX(SHA2(CONCAT('S@lt!',s.n),512)),
  'Active',
  c.first_name,
  c.last_name,
  -- email=`firstname.lastname####@example.com`
  CONCAT(LOWER(c.first_name),'.',LOWER(c.last_name),s.n,'@example.com'),
  -- phone=`555-###-####`
  CONCAT('555-',LPAD(s.n,3,'0'),'-',LPAD(s.n,4,'0'))
FROM `seq` AS s
JOIN `combos`  AS c ON c.combo_id = s.n
WHERE s.n <= 1000;

-- ============================================================================
-- 4) USER_ROLES: Assign roles: first 500 → Doctor, next 500 → Nurse
--    Columns: user_id, role_id
-- ============================================================================
INSERT INTO `user_roles` (`user_id`,`role_id`)
SELECT
  s.n AS user_id,
  CASE WHEN s.n <= 500
       THEN (SELECT role_id FROM roles WHERE role_name='Doctor')
       ELSE (SELECT role_id FROM roles WHERE role_name='Nurse')
  END AS role_id
FROM `seq` AS s
WHERE s.n <= 1000;

-- ============================================================================
-- 5) PATIENTS: Populate 1000 patients using combos 1001–2000
--    Adds realistic city/state/country/postal data and contacts
-- ============================================================================
INSERT INTO `patients` (
  `first_name`,`last_name`,`dob`,`gender`,
  `address_line1`,`address_line2`,`city`,`state`,`postal_code`,`country`,
  `phone_home`,`phone_mobile`,`email`,
  `emergency_contact_name`,`emergency_contact_relation`,`emergency_contact_phone`,
  `insurance_provider`,`insurance_policy_number`
)
SELECT
  c.first_name,
  c.last_name,
  -- date of birth in past ~82 years
  DATE_SUB(CURDATE(), INTERVAL ((s.n-1)%30000) DAY),
  -- gender round-robin
  ELT((s.n%3)+1,'Male','Female','Other'),
  -- street and apt
  CONCAT((s.n%999)+1,' ',ELT((s.n%5)+1,'Maple St','Oak Ave','Pine Rd','Cedar Blvd','Elm St')),
  CONCAT('Apt ',(s.n%500)+1),
  -- city from top 20 US cities
  ELT((s.n%20)+1,
    'New York','Los Angeles','Chicago','Houston','Phoenix',
    'Philadelphia','San Antonio','San Diego','Dallas','San Jose',
    'Austin','Jacksonville','Fort Worth','Columbus','Charlotte',
    'San Francisco','Indianapolis','Seattle','Denver','Washington'
  ),
  -- corresponding state codes
  ELT((s.n%20)+1,
    'NY','CA','IL','TX','AZ','PA','TX','CA','TX','CA',
    'TX','FL','TX','OH','NC','CA','IN','WA','CO','DC'
  ),
  -- random 5-digit postal
  LPAD(FLOOR(RAND()*90000)+10000,5,'0'),
  -- country list
  ELT((s.n%10)+1,
    'United States','Canada','United Kingdom','Australia','Germany',
    'France','Italy','Spain','Netherlands','Brazil'
  ),
  -- contact phones/emails
  CONCAT('800-',LPAD(s.n,3,'0'),'-',LPAD(s.n,4,'0')),
  CONCAT('800-',LPAD(s.n+500,3,'0'),'-',LPAD(s.n,4,'0')),
  CONCAT(LOWER(c.first_name),'.',LOWER(c.last_name),s.n,'@patient.com'),
  -- emergency contact reuse patient name
  CONCAT(c.first_name,' ',c.last_name,' Jr.'),
  ELT((s.n%3)+1,'Spouse','Parent','Child'),
  CONCAT('800-',LPAD(s.n+900,3,'0'),'-',LPAD(s.n,4,'0')),
  -- insurance static + policy#
  'InsureCo',
  CONCAT('POL',LPAD(s.n,6,'0'))
FROM (
  SELECT n+1000 AS n
  FROM `seq`
) AS s
JOIN `combos` AS c ON c.combo_id = s.n;

-- ============================================================================
-- 6) PATIENT_STAFF: Link patient #n → user #n (1:1 mapping)
-- ============================================================================
INSERT IGNORE INTO `patient_staff` (`patient_id`,`user_id`)
SELECT n, n FROM `seq`;

-- ============================================================================
-- 7) USER_DEPARTMENTS & PATIENT_DEPARTMENTS: Random assignments
-- ============================================================================
INSERT IGNORE INTO `user_departments` (`user_id`,`department_id`)
SELECT n, ((n % (SELECT COUNT(*) FROM departments)) + 1) FROM `seq`;

INSERT IGNORE INTO `patient_departments` (`patient_id`,`department_id`)
SELECT n, ((n % (SELECT COUNT(*) FROM departments)) + 1) FROM `seq`;

-- ============================================================================
-- 8) MEDICAL_RECORDS: 1000 records for patients
-- ============================================================================
INSERT INTO `medical_records` (
  `patient_id`,`created_by`,`record_type`,`record_date`,`description`,`file_path`
)
SELECT
  ((n%1000)+1),
  ((n%500)+1),
  ELT((n%4)+1,'Lab Report','Doctor Note','Imaging','Other'),
  DATE_SUB(CURDATE(), INTERVAL (n%365) DAY),
  CONCAT('Record #',n,' description'),
  NULL
FROM `seq`;

-- ============================================================================
-- 9) LAB_RESULTS: 1000 rows
-- ============================================================================
INSERT INTO `lab_results` (
  `record_id`,`test_name`,`test_value`,`test_units`,`performed_at`
)
SELECT
  ((n%1000)+1),
  ELT((n%5)+1,'Hemoglobin','WBC','Platelets','Glucose','Cholesterol'),
  ROUND(RAND()*200,2),
  'units',
  DATE_SUB(CURDATE(), INTERVAL (n%365) DAY)
FROM `seq`;

-- ============================================================================
-- 10) IMAGING_SCANS: 1000 rows
-- ============================================================================
INSERT INTO `imaging_scans` (
  `record_id`,`modality`,`body_part`,`scan_date`,`file_path`
)
SELECT
  ((n%1000)+1),
  ELT((n%4)+1,'X-Ray','CT','MRI','Ultrasound'),
  ELT((n%6)+1,'Chest','Head','Abdomen','Spine','Pelvis','Leg'),
  DATE_SUB(CURDATE(), INTERVAL (n%365) DAY),
  CONCAT('/tmp/scan',LPAD(n,4,'0'),'.dcm')
FROM `seq`;

-- ============================================================================
-- 11) VITALS: 1000 rows
-- ============================================================================
INSERT INTO `vitals` (
  `patient_id`,`measured_by`,`measurement_datetime`,
  `blood_pressure_systolic`,`blood_pressure_diastolic`,
  `heart_rate`,`respiratory_rate`,`temperature`,`oxygen_saturation`,
  `weight`,`height`,`notes`
)
SELECT
  ((n%1000)+1),
  ((n%500)+1),
  NOW() - INTERVAL n HOUR,
  110 + (n%20),
  70  + (n%10),
  60  + (n%40),
  12  + (n%8),
  ROUND(36 + RAND(),1),
  95  + (n%5),
  120 + (n%50),
  65  + (n%30),
  CONCAT('Vitals note ',n)
FROM `seq`;

-- ============================================================================
-- 12) APPOINTMENTS: 1000 rows
-- ============================================================================
INSERT INTO `appointments` (
  `patient_id`,`staff_id`,`appointment_datetime`,
  `duration_minutes`,`status`,`location`,`reason`,`notes`
)
SELECT
  ((n%1000)+1),
  ((n%500)+1),
  NOW() + INTERVAL (n%30) DAY,
  15 + ((n%4)*15),
  ELT((n%3)+1,'Scheduled','Completed','Cancelled'),
  CONCAT('Room ',(n%20)+1),
  CONCAT('Reason ',n),
  CONCAT('Note ',n)
FROM `seq`;

-- ============================================================================
-- 13) SEARCH_LOG: 1000 rows
-- ============================================================================
INSERT INTO `search_log` (
  `user_id`,`query_text`,`executed_at`
)
SELECT
  ((n%1000)+1),
  CONCAT('search ',n),
  NOW() - INTERVAL n MINUTE
FROM `seq`;

-- ============================================================================
-- Cleanup: remove all temporary helper tables
-- ============================================================================
DROP TEMPORARY TABLE IF EXISTS `combos`;
DROP TEMPORARY TABLE IF EXISTS `first_names`;
DROP TEMPORARY TABLE IF EXISTS `last_names`;
DROP TEMPORARY TABLE IF EXISTS `seq`;
DROP TEMPORARY TABLE IF EXISTS `digits`;
