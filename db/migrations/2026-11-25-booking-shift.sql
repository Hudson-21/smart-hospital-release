-- Run once, against the explicitly selected environment only. Do not backfill legacy rows.
ALTER TABLE `guahao`
  ADD COLUMN `booking_shift` VARCHAR(10) NULL DEFAULT NULL,
  ADD COLUMN `booking_request_id` CHAR(32) CHARACTER SET ascii COLLATE ascii_bin NULL DEFAULT NULL,
  ADD UNIQUE KEY `uk_guahao_patient_request` (`name`, `booking_request_id`);
