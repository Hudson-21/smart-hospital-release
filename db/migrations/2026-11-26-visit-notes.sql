-- Run once after booking-shift and prescription-cost. Never infer legacy identities.
ALTER TABLE guahao ADD COLUMN patient_account_id INT NULL,
  ADD CONSTRAINT fk_guahao_patient_account FOREIGN KEY (patient_account_id) REFERENCES loginuser(id);
ALTER TABLE bingli ADD COLUMN visit_id INT NULL,
  ADD CONSTRAINT fk_bingli_visit FOREIGN KEY (visit_id) REFERENCES guahao(id);
