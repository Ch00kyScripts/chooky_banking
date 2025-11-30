
CREATE TABLE IF NOT EXISTS `banking_loans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `borrower` varchar(50) NOT NULL,
  `borrower_id` int(11) NOT NULL,
  `amount` int(11) NOT NULL,
  `total_amount` int(11) NOT NULL,
  `interest` float NOT NULL,
  `duration` int(11) NOT NULL,
  `due_date` int(11) NOT NULL,
  `given_by` varchar(50) NOT NULL,
  `given_by_id` int(11) NOT NULL,
  `status` enum('active','paid','overdue') DEFAULT 'active',
  `created_at` int(11) NOT NULL DEFAULT unix_timestamp(),
  `paid_date` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `status` (`status`),
  KEY `borrower_id` (`borrower_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


CREATE TABLE IF NOT EXISTS `banking_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `banker` varchar(50) NOT NULL,
  `banker_id` int(11) NOT NULL,
  `target` varchar(50) NOT NULL,
  `target_id` int(11) NOT NULL,
  `action` varchar(50) NOT NULL,
  `amount` int(11) NOT NULL,
  `reason` text DEFAULT NULL,
  `timestamp` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `timestamp` (`timestamp`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


