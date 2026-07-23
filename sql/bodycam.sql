-- ─────────────────────────────────────────────────────────────────────────────
--  NDM Body Camera — Database Schema
--  Run this file once against your server's MySQL / MariaDB database.
--  Compatible with oxmysql.
-- ─────────────────────────────────────────────────────────────────────────────

-- Stores the permanent serial number assigned to each officer.
-- One row per citizen; subsequent logins reuse the same serial.
CREATE TABLE IF NOT EXISTS `bodycam_serials` (
    `id`         INT(11)      NOT NULL AUTO_INCREMENT,
    `citizen_id` VARCHAR(60)  NOT NULL,
    `serial`     VARCHAR(20)  NOT NULL,
    `issued_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_citizen`  (`citizen_id`),
    UNIQUE KEY `uq_serial`   (`serial`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Records every camera recording session (start / end timestamps).
CREATE TABLE IF NOT EXISTS `bodycam_logs` (
    `id`           INT(11)      NOT NULL AUTO_INCREMENT,
    `citizen_id`   VARCHAR(60)  NOT NULL,
    `officer_name` VARCHAR(100) NOT NULL,
    `callsign`     VARCHAR(20)  DEFAULT NULL,
    `serial`       VARCHAR(20)  NOT NULL,
    `job`          VARCHAR(50)  NOT NULL,
    `start_time`   DATETIME     NOT NULL,
    `end_time`     DATETIME     DEFAULT NULL,
    `created_at`   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_citizen` (`citizen_id`),
    KEY `idx_serial`  (`serial`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
