-- Run once in the explicitly selected database; no history is backfilled.
ALTER TABLE cost
  ADD COLUMN rx_item_id INT NULL DEFAULT NULL,
  ADD UNIQUE KEY uk_cost_rx_item (rx_item_id),
  ADD CONSTRAINT fk_cost_rx_item FOREIGN KEY (rx_item_id) REFERENCES cf_item(id);
