-- MySQL Schema for Patient Management System (Database “Crypto”)

/*===============================================================================
  1) DATABASE CREATION & SETTINGS
===============================================================================*/
-- 1.1 Create database with full Unicode support
CREATE DATABASE IF NOT EXISTS `crypto`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE `crypto`;

-- 1.2 Enable the event scheduler for automated backups
SET GLOBAL event_scheduler = ON;

/*===============================================================================
  2) ROLE-BASED ACCESS CONTROL (RBAC)
     Define roles, permissions, and assign them
===============================================================================*/
-- 2.1 Roles: user categories (Doctor vs Nurse)
CREATE TABLE IF NOT EXISTS `roles` (
  `role_id`   INT AUTO_INCREMENT PRIMARY KEY,
  `role_name` VARCHAR(50)    NOT NULL UNIQUE,
  `description` VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2.2 Permissions: fine-grained actions
CREATE TABLE IF NOT EXISTS `permissions` (
  `perm_id`   INT AUTO_INCREMENT PRIMARY KEY,
  `perm_name` VARCHAR(100)   NOT NULL UNIQUE,
  `description` VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2.3 Link roles to permissions
CREATE TABLE IF NOT EXISTS `role_permissions` (
  `role_id` INT NOT NULL,
  `perm_id` INT NOT NULL,
  PRIMARY KEY (`role_id`,`perm_id`),
  FOREIGN KEY (`role_id`) REFERENCES `roles`(`role_id`) ON DELETE CASCADE,
  FOREIGN KEY (`perm_id`) REFERENCES `permissions`(`perm_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2.4 Seed roles
INSERT IGNORE INTO `roles` (`role_name`,`description`) VALUES
  ('Doctor','Full access to all patient data and vitals'),
  ('Nurse','Can view demographics & add/manage vitals only');

-- 2.5 Seed permissions
INSERT IGNORE INTO `permissions` (`perm_name`,`description`) VALUES
  ('VIEW_PATIENT','View patient demographics'),
  ('EDIT_PATIENT','Edit patient demographics'),
  ('VIEW_RECORD','View medical records'),
  ('EDIT_RECORD','Add or modify medical records'),
  ('DELETE_RECORD','Remove medical records'),
  ('VIEW_VITALS','View vitals history'),
  ('EDIT_VITALS','Add or modify vitals entries'),
  ('SCHEDULE_APPOINTMENT','Schedule patient appointments'),
  ('CANCEL_APPOINTMENT','Cancel appointments');

-- 2.6 Assign permissions to roles
INSERT IGNORE INTO `role_permissions` (`role_id`,`perm_id`)
  SELECT r.`role_id`, p.`perm_id`
    FROM `roles` r CROSS JOIN `permissions` p
   WHERE r.`role_name` = 'Doctor'
UNION ALL
  SELECT r.`role_id`, p.`perm_id`
    FROM `roles` r
    JOIN `permissions` p ON p.`perm_name` 
      IN ('VIEW_PATIENT','VIEW_RECORD','VIEW_VITALS','EDIT_VITALS')
   WHERE r.`role_name` = 'Nurse';

/*===============================================================================
  3) USERS & USER_ROLES
     Store application users and assign RBAC roles
===============================================================================*/
-- 3.1 Users: login credentials + encrypted profile fields
CREATE TABLE IF NOT EXISTS `users` (
  `user_id`       INT AUTO_INCREMENT PRIMARY KEY,
  `username`      VARCHAR(50)    NOT NULL UNIQUE,
  `password_hash` VARBINARY(255) NOT NULL,
  `password_salt` VARBINARY(64)  NOT NULL,
  `status`        ENUM('Active','Inactive','Pending') NOT NULL DEFAULT 'Active',
  `first_name`    VARBINARY(255) NOT NULL,
  `last_name`     VARBINARY(255) NOT NULL,
  `email`         VARBINARY(255) NOT NULL UNIQUE,
  `phone`         VARBINARY(255),
  `last_login`    DATETIME,
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3.2 Link users to roles (many-to-many)
CREATE TABLE IF NOT EXISTS `user_roles` (
  `user_id` INT NOT NULL,
  `role_id` INT NOT NULL,
  PRIMARY KEY (`user_id`,`role_id`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE,
  FOREIGN KEY (`role_id`) REFERENCES `roles`(`role_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/*===============================================================================
  4) PATIENTS (Encrypted + Soft-Delete)
     Securely store PII with triggers & present via view
===============================================================================*/
CREATE TABLE IF NOT EXISTS `patients` (
  `patient_id`               INT AUTO_INCREMENT PRIMARY KEY,
  `first_name`               VARBINARY(255) NOT NULL,
  `last_name`                VARBINARY(255) NOT NULL,
  `dob`                      DATE          NOT NULL,
  `gender`                   ENUM('Male','Female','Other') NOT NULL,
  `address_line1`            VARBINARY(255),
  `address_line2`            VARBINARY(255),
  `city`                     VARBINARY(255),
  `state`                    VARBINARY(255),
  `postal_code`              VARBINARY(255),
  `country`                  VARBINARY(255),
  `phone_home`               VARBINARY(255),
  `phone_mobile`             VARBINARY(255),
  `email`                    VARBINARY(255),
  `emergency_contact_name`   VARBINARY(255),
  `emergency_contact_relation` VARBINARY(255),
  `emergency_contact_phone`  VARBINARY(255),
  `insurance_provider`       VARBINARY(255),
  `insurance_policy_number`  VARBINARY(255),
  `is_deleted`               BOOLEAN       NOT NULL DEFAULT FALSE,
  `created_at`               TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `updated_at`               TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELIMITER $$
-- Encrypt PII on insert
CREATE TRIGGER `trg_encrypt_patients_ins`
BEFORE INSERT ON `patients` FOR EACH ROW
BEGIN
  SET NEW.first_name  = AES_ENCRYPT(NEW.first_name,  UNHEX(SHA2('testing',512))); -- testing is passcode
  SET NEW.last_name   = AES_ENCRYPT(NEW.last_name,   UNHEX(SHA2('testing',512)));
  SET NEW.address_line1 = AES_ENCRYPT(NEW.address_line1, UNHEX(SHA2('testing',512)));
  SET NEW.address_line2 = AES_ENCRYPT(NEW.address_line2, UNHEX(SHA2('testing',512)));
  SET NEW.city        = AES_ENCRYPT(NEW.city,        UNHEX(SHA2('testing',512)));
  SET NEW.state       = AES_ENCRYPT(NEW.state,       UNHEX(SHA2('testing',512)));
  SET NEW.postal_code = AES_ENCRYPT(NEW.postal_code, UNHEX(SHA2('testing',512)));
  SET NEW.country     = AES_ENCRYPT(NEW.country,     UNHEX(SHA2('testing',512)));
  SET NEW.phone_home  = AES_ENCRYPT(NEW.phone_home,  UNHEX(SHA2('testing',512)));
  SET NEW.phone_mobile= AES_ENCRYPT(NEW.phone_mobile,UNHEX(SHA2('testing',512)));
  SET NEW.email       = AES_ENCRYPT(NEW.email,       UNHEX(SHA2('testing',512)));
  SET NEW.emergency_contact_name     = AES_ENCRYPT(NEW.emergency_contact_name,     UNHEX(SHA2('testing',512)));
  SET NEW.emergency_contact_relation = AES_ENCRYPT(NEW.emergency_contact_relation, UNHEX(SHA2('testing',512)));
  SET NEW.emergency_contact_phone    = AES_ENCRYPT(NEW.emergency_contact_phone,    UNHEX(SHA2('testing',512)));
  SET NEW.insurance_provider         = AES_ENCRYPT(NEW.insurance_provider,         UNHEX(SHA2('testing',512)));
  SET NEW.insurance_policy_number    = AES_ENCRYPT(NEW.insurance_policy_number,    UNHEX(SHA2('testing',512)));
END$$

-- Re-encrypt on update
CREATE TRIGGER `trg_encrypt_patients_upd`
BEFORE UPDATE ON `patients` FOR EACH ROW
BEGIN
  SET NEW.first_name  = AES_ENCRYPT(NEW.first_name,  UNHEX(SHA2('testing',512)));
  SET NEW.last_name   = AES_ENCRYPT(NEW.last_name,   UNHEX(SHA2('testing',512)));
  SET NEW.address_line1 = AES_ENCRYPT(NEW.address_line1, UNHEX(SHA2('testing',512)));
  SET NEW.address_line2 = AES_ENCRYPT(NEW.address_line2, UNHEX(SHA2('testing',512)));
  SET NEW.city        = AES_ENCRYPT(NEW.city,        UNHEX(SHA2('testing',512)));
  SET NEW.state       = AES_ENCRYPT(NEW.state,       UNHEX(SHA2('testing',512)));
  SET NEW.postal_code = AES_ENCRYPT(NEW.postal_code, UNHEX(SHA2('testing',512)));
  SET NEW.country     = AES_ENCRYPT(NEW.country,     UNHEX(SHA2('testing',512)));
  SET NEW.phone_home  = AES_ENCRYPT(NEW.phone_home,  UNHEX(SHA2('testing',512)));
  SET NEW.phone_mobile= AES_ENCRYPT(NEW.phone_mobile,UNHEX(SHA2('testing',512)));
  SET NEW.email       = AES_ENCRYPT(NEW.email,       UNHEX(SHA2('testing',512)));
  SET NEW.emergency_contact_name     = AES_ENCRYPT(NEW.emergency_contact_name,     UNHEX(SHA2('testing',512)));
  SET NEW.emergency_contact_relation = AES_ENCRYPT(NEW.emergency_contact_relation, UNHEX(SHA2('testing',512)));
  SET NEW.emergency_contact_phone    = AES_ENCRYPT(NEW.emergency_contact_phone,    UNHEX(SHA2('testing',512)));
  SET NEW.insurance_provider         = AES_ENCRYPT(NEW.insurance_provider,         UNHEX(SHA2('testing',512)));
  SET NEW.insurance_policy_number    = AES_ENCRYPT(NEW.insurance_policy_number,    UNHEX(SHA2('testing',512)));
  -- add others if updated
END$$
DELIMITER ;

-- Decryption view excludes soft‐deleted rows
CREATE OR REPLACE VIEW `vw_patients` AS
SELECT
  patient_id,
  CAST(AES_DECRYPT(first_name,  UNHEX(SHA2('testing',512))) AS CHAR) AS first_name,
  CAST(AES_DECRYPT(last_name,   UNHEX(SHA2('testing',512))) AS CHAR) AS last_name,
  dob, gender,
  CAST(AES_DECRYPT(address_line1, UNHEX(SHA2('testing',512))) AS CHAR) AS address_line1,
  CAST(AES_DECRYPT(address_line2, UNHEX(SHA2('testing',512))) AS CHAR) AS address_line2,
  CAST(AES_DECRYPT(city,          UNHEX(SHA2('testing',512))) AS CHAR) AS city,
  CAST(AES_DECRYPT(state,         UNHEX(SHA2('testing',512))) AS CHAR) AS state,
  CAST(AES_DECRYPT(postal_code,   UNHEX(SHA2('testing',512))) AS CHAR) AS postal_code,
  CAST(AES_DECRYPT(country,       UNHEX(SHA2('testing',512))) AS CHAR) AS country,
  CAST(AES_DECRYPT(phone_home,    UNHEX(SHA2('testing',512))) AS CHAR) AS phone_home,
  CAST(AES_DECRYPT(phone_mobile,  UNHEX(SHA2('testing',512))) AS CHAR) AS phone_mobile,
  CAST(AES_DECRYPT(email,         UNHEX(SHA2('testing',512))) AS CHAR) AS email,
  CAST(AES_DECRYPT(emergency_contact_name,     UNHEX(SHA2('testing',512))) AS CHAR) AS emergency_contact_name,
  CAST(AES_DECRYPT(emergency_contact_relation, UNHEX(SHA2('testing',512))) AS CHAR) AS emergency_contact_relation,
  CAST(AES_DECRYPT(emergency_contact_phone,    UNHEX(SHA2('testing',512))) AS CHAR) AS emergency_contact_phone,
  CAST(AES_DECRYPT(insurance_provider,         UNHEX(SHA2('testing',512))) AS CHAR) AS insurance_provider,
  CAST(AES_DECRYPT(insurance_policy_number,    UNHEX(SHA2('testing',512))) AS CHAR) AS insurance_policy_number,
  created_at, updated_at
FROM `patients`
WHERE is_deleted = FALSE;

/*===============================================================================
  5) PATIENT–STAFF ASSIGNMENTS
     Which staff members are responsible for each patient
===============================================================================*/
CREATE TABLE IF NOT EXISTS `patient_staff` (
  `patient_id` INT NOT NULL,
  `user_id`    INT NOT NULL,
  `assigned_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`patient_id`,`user_id`),
  FOREIGN KEY (`patient_id`) REFERENCES `patients`(`patient_id`) ON DELETE CASCADE,
  FOREIGN KEY (`user_id`)    REFERENCES `users`(`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/*===============================================================================
  6) MEDICAL_RECORDS
     Encrypted entries, versioned history, full-text search
===============================================================================*/
CREATE TABLE IF NOT EXISTS `medical_records` (
  `record_id`   INT AUTO_INCREMENT PRIMARY KEY,
  `patient_id`  INT NOT NULL,
  `created_by`  INT NOT NULL,
  `record_type` ENUM('Lab Report','Doctor Note','Imaging','Other') NOT NULL,
  `record_date` DATE NOT NULL,
  `version`     INT NOT NULL DEFAULT 1,
  `description` VARBINARY(1024),
  `file_path`   VARBINARY(255),
  `is_encrypted` BOOLEAN NOT NULL DEFAULT TRUE,
  `created_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`patient_id`) REFERENCES `patients`(`patient_id`),
  FOREIGN KEY (`created_by`) REFERENCES `users`(`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6.1 Plain‐text generated column for efficient full-text on decrypted descriptions
ALTER TABLE `medical_records`
  ADD COLUMN `description_plain` TEXT GENERATED ALWAYS AS (
    CAST(AES_DECRYPT(description, UNHEX(SHA2('testing',512))) AS CHAR(1024))
  ) STORED,
  ADD FULLTEXT (`description_plain`);

-- 6.2 Archive table for previous versions
CREATE TABLE IF NOT EXISTS `medical_records_history` LIKE `medical_records`;

-- 1) Remove AUTO_INCREMENT from record_id, and drop the old PK
ALTER TABLE `medical_records_history`
  MODIFY COLUMN `record_id` INT NOT NULL,
  DROP PRIMARY KEY;

-- 2) Add your new history_id as the AUTO_INCREMENT PK
ALTER TABLE `medical_records_history`
  ADD COLUMN `history_id` INT NOT NULL AUTO_INCREMENT FIRST,
  ADD PRIMARY KEY (`history_id`);
DELIMITER $$

-- 6.3 Encrypt on insert
CREATE TRIGGER `trg_encrypt_medrec_ins`
BEFORE INSERT ON `medical_records` FOR EACH ROW
BEGIN
  SET NEW.description = AES_ENCRYPT(NEW.description, UNHEX(SHA2('testing',512)));
  SET NEW.file_path   = AES_ENCRYPT(NEW.file_path,   UNHEX(SHA2('testing',512)));
END$$

-- 6.4 Archive & bump version on update
CREATE TRIGGER `trg_medrec_audit_upd`
BEFORE UPDATE ON `medical_records`
FOR EACH ROW
BEGIN
  /* 1) copy every OLD field into the history table */
  INSERT INTO `medical_records_history` (
    record_id,
    patient_id,
    created_by,
    record_type,
    record_date,
    version,
    description,
    file_path,
    is_encrypted,
    created_at,
    updated_at
  ) VALUES (
    OLD.record_id,
    OLD.patient_id,
    OLD.created_by,
    OLD.record_type,
    OLD.record_date,
    OLD.version,
    OLD.description,
    OLD.file_path,
    OLD.is_encrypted,
    OLD.created_at,
    OLD.updated_at
  );
  /* 2) bump the version on the new row */
  SET NEW.version = OLD.version + 1;
END$$

-- 6.5 Archive on delete
CREATE TRIGGER `trg_medrec_audit_del`
BEFORE DELETE ON `medical_records`
FOR EACH ROW
BEGIN
  INSERT INTO `medical_records_history` (
    record_id,
    patient_id,
    created_by,
    record_type,
    record_date,
    version,
    description,
    file_path,
    is_encrypted,
    created_at,
    updated_at
  ) VALUES (
    OLD.record_id,
    OLD.patient_id,
    OLD.created_by,
    OLD.record_type,
    OLD.record_date,
    OLD.version,
    OLD.description,
    OLD.file_path,
    OLD.is_encrypted,
    OLD.created_at,
    OLD.updated_at
  );
END$$
DELIMITER ;

/*===============================================================================
  7) VITALS
     Measurements + auto‐calculated BMI + history + full-text notes
===============================================================================*/
CREATE TABLE IF NOT EXISTS `vitals` (
  `vital_id`             INT AUTO_INCREMENT PRIMARY KEY,
  `patient_id`           INT NOT NULL,
  `measured_by`          INT,
  `measurement_datetime` DATETIME NOT NULL,
  `blood_pressure_systolic`   SMALLINT,
  `blood_pressure_diastolic`  SMALLINT,
  `heart_rate`                SMALLINT,
  `respiratory_rate`          SMALLINT,
  `temperature`               DECIMAL(4,1),
  `oxygen_saturation`         SMALLINT,
  `weight`                    DECIMAL(5,2),
  `height`                    DECIMAL(4,1),
  `bmi`                       DECIMAL(4,1) GENERATED ALWAYS AS (weight/(height*height)*703) STORED,
  `notes`                     TEXT,
  `created_at`               TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`               TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`patient_id`) REFERENCES `patients`(`patient_id`),
  FOREIGN KEY (`measured_by`) REFERENCES `users`(`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 7.1 Full-text on notes
ALTER TABLE `vitals` ADD FULLTEXT (`notes`);

-- 7.2 History table
CREATE TABLE IF NOT EXISTS `vitals_history` LIKE `vitals`;

-- 1) Remove AUTO_INCREMENT from vital_id, and drop the old PK
ALTER TABLE `vitals_history`
  MODIFY COLUMN `vital_id` INT NOT NULL,
  DROP PRIMARY KEY;

-- 2) Add your new y_id as the AUTO_INCREMENT PK
ALTER TABLE `vitals_history`
  ADD COLUMN `history_id` INT NOT NULL AUTO_INCREMENT FIRST,
  ADD PRIMARY KEY (`history_id`);
DELIMITER $$

-- 7.3 Archive on update
CREATE TRIGGER `trg_vitals_audit_upd`
BEFORE UPDATE ON `vitals`
FOR EACH ROW
BEGIN
  INSERT INTO `vitals_history` (
    `vital_id`,
    `patient_id`,
    `measured_by`,
    `measurement_datetime`,
    `blood_pressure_systolic`,
    `blood_pressure_diastolic`,
    `heart_rate`,
    `respiratory_rate`,
    `temperature`,
    `oxygen_saturation`,
    `weight`,
    `height`,
    `bmi`,
    `notes`,
    `created_at`,
    `updated_at`
  ) VALUES (
    OLD.`vital_id`,
    OLD.`patient_id`,
    OLD.`measured_by`,
    OLD.`measurement_datetime`,
    OLD.`blood_pressure_systolic`,
    OLD.`blood_pressure_diastolic`,
    OLD.`heart_rate`,
    OLD.`respiratory_rate`,
    OLD.`temperature`,
    OLD.`oxygen_saturation`,
    OLD.`weight`,
    OLD.`height`,
    OLD.`bmi`,
    OLD.`notes`,
    OLD.`created_at`,
    OLD.`updated_at`
  );
END$$

-- 7.4 Archive on delete
CREATE TRIGGER `trg_vitals_audit_del`
BEFORE DELETE ON `vitals`
FOR EACH ROW
BEGIN
  INSERT INTO `vitals_history` (
    `vital_id`,
    `patient_id`,
    `measured_by`,
    `measurement_datetime`,
    `blood_pressure_systolic`,
    `blood_pressure_diastolic`,
    `heart_rate`,
    `respiratory_rate`,
    `temperature`,
    `oxygen_saturation`,
    `weight`,
    `height`,
    `bmi`,
    `notes`,
    `created_at`,
    `updated_at`
  ) VALUES (
    OLD.`vital_id`,
    OLD.`patient_id`,
    OLD.`measured_by`,
    OLD.`measurement_datetime`,
    OLD.`blood_pressure_systolic`,
    OLD.`blood_pressure_diastolic`,
    OLD.`heart_rate`,
    OLD.`respiratory_rate`,
    OLD.`temperature`,
    OLD.`oxygen_saturation`,
    OLD.`weight`,
    OLD.`height`,
    OLD.`bmi`,
    OLD.`notes`,
    OLD.`created_at`,
    OLD.`updated_at`
  );
END$$
DELIMITER ;

/*===============================================================================
  8) APPOINTMENTS
     Schedule, track, and full-text notes
===============================================================================*/
CREATE TABLE IF NOT EXISTS `appointments` (
  `appointment_id`       INT AUTO_INCREMENT PRIMARY KEY,
  `patient_id`           INT NOT NULL,
  `staff_id`             INT NOT NULL,
  `appointment_datetime` DATETIME NOT NULL,
  `duration_minutes`     SMALLINT NOT NULL DEFAULT 30,
  `status`               ENUM('Scheduled','Completed','Cancelled') NOT NULL DEFAULT 'Scheduled',
  `location`             VARCHAR(100),
  `reason`               VARCHAR(255),
  `notes`                TEXT,
  `created_at`           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`patient_id`) REFERENCES `patients`(`patient_id`),
  FOREIGN KEY (`staff_id`)   REFERENCES `users`(`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 8.1 Full-text on notes
ALTER TABLE `appointments` ADD FULLTEXT (`notes`);

/*===============================================================================
  9) SEARCH_LOG
     Audit user search queries
===============================================================================*/
CREATE TABLE IF NOT EXISTS `search_log` (
  `log_id`      INT AUTO_INCREMENT PRIMARY KEY,
  `user_id`     INT NOT NULL,
  `query_text`  TEXT NOT NULL,
  `executed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX `idx_search_log_user` ON `search_log`(`user_id`);
CREATE INDEX `idx_search_log_time` ON `search_log`(`executed_at`);

/*===============================================================================
 10) DEPARTMENTS/WARDS
     Organize staff & patients by hospital unit
===============================================================================*/
CREATE TABLE IF NOT EXISTS `departments` (
  `department_id`   INT AUTO_INCREMENT PRIMARY KEY,
  `department_name` VARCHAR(100) NOT NULL,
  `ward`            VARCHAR(100),
  `location`        VARCHAR(100),
  `description`     TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 10.1 Staff assignments
CREATE TABLE IF NOT EXISTS `user_departments` (
  `user_id`       INT NOT NULL,
  `department_id` INT NOT NULL,
  PRIMARY KEY (`user_id`,`department_id`),
  FOREIGN KEY (`user_id`)       REFERENCES `users`(`user_id`) ON DELETE CASCADE,
  FOREIGN KEY (`department_id`) REFERENCES `departments`(`department_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 10.2 Patient assignments
CREATE TABLE IF NOT EXISTS `patient_departments` (
  `patient_id`    INT NOT NULL,
  `department_id` INT NOT NULL,
  PRIMARY KEY (`patient_id`,`department_id`),
  FOREIGN KEY (`patient_id`)    REFERENCES `patients`(`patient_id`) ON DELETE CASCADE,
  FOREIGN KEY (`department_id`) REFERENCES `departments`(`department_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/*===============================================================================
 11) LAB_RESULTS
     Structured lab test entries
===============================================================================*/
CREATE TABLE IF NOT EXISTS `lab_results` (
  `lab_result_id` INT AUTO_INCREMENT PRIMARY KEY,
  `record_id`     INT NOT NULL,
  `test_name`     VARCHAR(100) NOT NULL,
  `test_value`    DECIMAL(10,2) NOT NULL,
  `test_units`    VARCHAR(50),
  `ref_range_low` DECIMAL(10,2),
  `ref_range_high` DECIMAL(10,2),
  `performed_at`  DATETIME NOT NULL,
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`record_id`) REFERENCES `medical_records`(`record_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX `idx_lab_results_test` ON `lab_results`(`test_name`);

/*===============================================================================
 12) IMAGING_SCANS
     Metadata & encrypted pointers for radiology
===============================================================================*/
CREATE TABLE IF NOT EXISTS `imaging_scans` (
  `imaging_id`    INT AUTO_INCREMENT PRIMARY KEY,
  `record_id`     INT NOT NULL,
  `modality`      ENUM('X-Ray','MRI','CT','Ultrasound','PET','Other') NOT NULL,
  `body_part`     VARCHAR(100),
  `scan_date`     DATETIME NOT NULL,
  `file_path`     VARBINARY(255),
  `is_encrypted`  BOOLEAN NOT NULL DEFAULT TRUE,
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`record_id`) REFERENCES `medical_records`(`record_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELIMITER $$
-- Encrypt file_path on insert/update
CREATE TRIGGER `trg_encrypt_imaging_ins`
BEFORE INSERT ON `imaging_scans` FOR EACH ROW
BEGIN
  SET NEW.file_path = AES_ENCRYPT(NEW.file_path, UNHEX(SHA2('testing',512)));
END$$
CREATE TRIGGER `trg_encrypt_imaging_upd`
BEFORE UPDATE ON `imaging_scans` FOR EACH ROW
BEGIN
  SET NEW.file_path = AES_ENCRYPT(NEW.file_path, UNHEX(SHA2('testing',512)));
END$$
DELIMITER ;

-- Decryption view for imaging metadata
CREATE OR REPLACE VIEW `vw_imaging_scans` AS
SELECT
  imaging_id,
  record_id,
  modality,
  body_part,
  scan_date,
  CAST(AES_DECRYPT(file_path,UNHEX(SHA2('testing',512))) AS CHAR) AS file_path,
  created_at
FROM `imaging_scans`;

/*===============================================================================
 13) STAFF VIEWS
     Convenient doctor/nurse “tables”
===============================================================================*/
CREATE OR REPLACE VIEW `doctors` AS
SELECT u.* FROM `users` u
JOIN `user_roles` ur ON u.user_id=ur.user_id
JOIN `roles` r       ON ur.role_id =r.role_id
WHERE r.role_name='Doctor';

CREATE OR REPLACE VIEW `nurses` AS
SELECT u.* FROM `users` u
JOIN `user_roles` ur ON u.user_id=ur.user_id
JOIN `roles` r       ON ur.role_id =r.role_id
WHERE r.role_name='Nurse';

/*===============================================================================
 14) PERFORMANCE INDEXES
     Speed up common queries
===============================================================================*/
CREATE INDEX `idx_roles_name`            ON `roles`(`role_name`);
CREATE INDEX `idx_permissions_name`      ON `permissions`(`perm_name`);
CREATE INDEX `idx_user_roles_role`       ON `user_roles`(`role_id`);
CREATE INDEX `idx_users_status`          ON `users`(`status`);
CREATE INDEX `idx_patients_dob`          ON `patients`(`dob`);
CREATE INDEX `idx_patients_gender`       ON `patients`(`gender`);
CREATE INDEX `idx_medrec_patient`        ON `medical_records`(`patient_id`);
CREATE INDEX `idx_medrec_created_by`     ON `medical_records`(`created_by`);
CREATE INDEX `idx_medrec_type`           ON `medical_records`(`record_type`);
CREATE INDEX `idx_medrec_date`           ON `medical_records`(`record_date`);
CREATE INDEX `idx_medrec_plain`          ON `medical_records`(`description_plain`);
CREATE INDEX `idx_vitals_patient`        ON `vitals`(`patient_id`);
CREATE INDEX `idx_vitals_datetime`       ON `vitals`(`measurement_datetime`);
CREATE INDEX `idx_appointments_patient`  ON `appointments`(`patient_id`);
CREATE INDEX `idx_appointments_staff`    ON `appointments`(`staff_id`);
CREATE INDEX `idx_appointments_datetime` ON `appointments`(`appointment_datetime`);
CREATE INDEX `idx_appointments_status`   ON `appointments`(`status`);
CREATE INDEX `idx_lab_result_test`      ON `lab_results`(`test_name`);
CREATE INDEX `idx_departments_name`      ON `departments`(`department_name`);
CREATE INDEX `idx_user_departments_dept` ON `user_departments`(`department_id`);
CREATE INDEX `idx_patient_departments`   ON `patient_departments`(`department_id`);
CREATE INDEX `idx_imaging_modality`      ON `imaging_scans`(`modality`);

/*===============================================================================
 15) BACKUP & RECOVERY via MySQL EVENTS
     Daily snapshots of core tables
===============================================================================*/
-- 15.1 Prepare backup tables
CREATE TABLE IF NOT EXISTS `patients_backup`        LIKE `patients`;
CREATE TABLE IF NOT EXISTS `medical_records_backup` LIKE `medical_records`;
CREATE TABLE IF NOT EXISTS `vitals_backup`          LIKE `vitals`;
CREATE TABLE IF NOT EXISTS `appointments_backup`    LIKE `appointments`;
CREATE TABLE IF NOT EXISTS `lab_results_backup`     LIKE `lab_results`;
CREATE TABLE IF NOT EXISTS `imaging_scans_backup`   LIKE `imaging_scans`;

DELIMITER $$
-- 15.2 Patients
CREATE EVENT IF NOT EXISTS `ev_backup_patients`
  ON SCHEDULE EVERY 1 DAY STARTS CURRENT_TIMESTAMP + INTERVAL 1 DAY
DO BEGIN
  TRUNCATE TABLE `patients_backup`;
  INSERT INTO `patients_backup` SELECT * FROM `patients`;
END$$

-- 15.3 Medical Records
CREATE EVENT IF NOT EXISTS `ev_backup_medical_records`
  ON SCHEDULE EVERY 1 DAY STARTS CURRENT_TIMESTAMP + INTERVAL 1 DAY
DO BEGIN
  TRUNCATE TABLE `medical_records_backup`;
  INSERT INTO `medical_records_backup` SELECT * FROM `medical_records`;
END$$

-- 15.4 Vitals
CREATE EVENT IF NOT EXISTS `ev_backup_vitals`
  ON SCHEDULE EVERY 1 DAY STARTS CURRENT_TIMESTAMP + INTERVAL 1 DAY
DO BEGIN
  TRUNCATE TABLE `vitals_backup`;
  INSERT INTO `vitals_backup` SELECT * FROM `vitals`;
END$$

-- 15.5 Appointments
CREATE EVENT IF NOT EXISTS `ev_backup_appointments`
  ON SCHEDULE EVERY 1 DAY STARTS CURRENT_TIMESTAMP + INTERVAL 1 DAY
DO BEGIN
  TRUNCATE TABLE `appointments_backup`;
  INSERT INTO `appointments_backup` SELECT * FROM `appointments`;
END$$

-- 15.6 Lab Results
CREATE EVENT IF NOT EXISTS `ev_backup_lab_results`
  ON SCHEDULE EVERY 1 DAY STARTS CURRENT_TIMESTAMP + INTERVAL 1 DAY
DO BEGIN
  TRUNCATE TABLE `lab_results_backup`;
  INSERT INTO `lab_results_backup` SELECT * FROM `lab_results`;
END$$

-- 15.7 Imaging Scans
CREATE EVENT IF NOT EXISTS `ev_backup_imaging_scans`
  ON SCHEDULE EVERY 1 DAY STARTS CURRENT_TIMESTAMP + INTERVAL 1 DAY
DO BEGIN
  TRUNCATE TABLE `imaging_scans_backup`;
  INSERT INTO `imaging_scans_backup` SELECT * FROM `imaging_scans`;
END$$
DELIMITER ;

-- End of schema.
