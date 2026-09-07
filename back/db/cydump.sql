-- MySQL dump 10.13  Distrib 8.4.2, for Win64 (x86_64)
--
-- Host: localhost    Database: cychronos
-- ------------------------------------------------------
-- Server version	8.4.2

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `location_log`
--

DROP TABLE IF EXISTS `location_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `location_log` (
  `log_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `trip_id` bigint unsigned NOT NULL,
  `log_num` int unsigned NOT NULL,
  `lat` decimal(10,7) NOT NULL,
  `lng` decimal(10,7) NOT NULL,
  `recorded_at` datetime NOT NULL,
  `speed_kmh` decimal(5,2) DEFAULT NULL,
  `accuracy_m` decimal(6,2) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`log_id`),
  UNIQUE KEY `uq_location_log_trip_log_num` (`trip_id`,`log_num`),
  KEY `idx_location_log_trip_recorded_at` (`trip_id`,`recorded_at`),
  CONSTRAINT `fk_location_log_trip` FOREIGN KEY (`trip_id`) REFERENCES `trip_history` (`trip_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `location_log`
--

LOCK TABLES `location_log` WRITE;
/*!40000 ALTER TABLE `location_log` DISABLE KEYS */;
INSERT INTO `location_log` VALUES (1,1,1,34.6937000,135.5023000,'2026-06-26 10:00:10',0.00,5.20,'2026-06-26 12:03:24'),(2,1,2,34.6941000,135.5030000,'2026-06-26 10:05:00',10.50,4.80,'2026-06-26 12:03:24'),(3,1,3,34.6950000,135.5042000,'2026-06-26 10:10:00',12.20,6.10,'2026-06-26 12:03:24'),(4,1,4,34.6873000,135.5262000,'2026-06-26 11:20:00',0.00,5.00,'2026-06-26 12:03:24'),(5,2,1,34.6937000,135.5023000,'2026-06-25 14:00:10',0.00,5.50,'2026-06-26 12:03:24'),(6,2,2,34.6805000,135.4900000,'2026-06-25 14:20:00',13.00,6.30,'2026-06-26 12:03:24'),(7,2,3,34.6551000,135.4289000,'2026-06-25 15:10:00',0.00,5.70,'2026-06-26 12:03:24'),(8,3,1,34.7000000,135.5000000,'2026-06-26 08:30:10',0.00,4.90,'2026-06-26 12:03:24'),(9,3,2,34.6978000,135.5015000,'2026-06-26 08:35:00',11.80,5.40,'2026-06-26 12:03:24'),(10,3,3,34.6929000,135.5031000,'2026-06-26 08:40:00',12.60,5.10,'2026-06-26 12:03:24'),(11,1,5,34.7000000,135.5100000,'2026-07-03 11:25:02',NULL,NULL,'2026-07-03 11:25:02'),(12,4,1,34.6900000,135.5000000,'2026-07-03 11:52:32',NULL,NULL,'2026-07-03 11:52:32'),(13,5,1,42.0000000,42.0000000,'2026-07-03 13:11:10',NULL,NULL,'2026-07-03 13:11:10'),(14,6,1,30.0000000,30.0000000,'2026-07-05 21:12:38',NULL,NULL,'2026-07-05 21:12:38'),(15,6,2,31.0000000,31.0000000,'2026-07-05 21:12:58',NULL,NULL,'2026-07-05 21:12:58'),(16,6,3,32.0000000,32.0000000,'2026-07-05 21:13:06',NULL,NULL,'2026-07-05 21:13:06'),(17,6,4,33.0000000,33.0000000,'2026-07-05 21:14:45',NULL,NULL,'2026-07-05 21:14:45'),(18,6,5,34.0000000,34.0000000,'2026-07-05 21:14:52',NULL,NULL,'2026-07-05 21:14:52'),(19,6,6,35.0000000,35.0000000,'2026-07-05 21:15:00',NULL,NULL,'2026-07-05 21:15:00'),(20,6,7,36.0000000,36.0000000,'2026-07-05 21:15:10',NULL,NULL,'2026-07-05 21:15:10');
/*!40000 ALTER TABLE `location_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `trip_history`
--

DROP TABLE IF EXISTS `trip_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `trip_history` (
  `trip_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `destination_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `destination_place_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `destination_url` text COLLATE utf8mb4_unicode_ci,
  `start_time` datetime NOT NULL,
  `end_time` datetime DEFAULT NULL,
  `total_distance_m` int unsigned DEFAULT NULL,
  `duration_sec` int unsigned DEFAULT NULL,
  `average_speed_kmh` decimal(5,2) DEFAULT NULL,
  `status` enum('active','completed','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'active',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`trip_id`),
  KEY `idx_trip_history_user_start` (`user_id`,`deleted_at`,`start_time`),
  KEY `idx_trip_history_status` (`status`),
  KEY `idx_trip_history_user_destination_place` (`user_id`,`destination_place_id`),
  CONSTRAINT `fk_trip_history_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `trip_history`
--

LOCK TABLES `trip_history` WRITE;
/*!40000 ALTER TABLE `trip_history` DISABLE KEYS */;
INSERT INTO `trip_history` VALUES (1,1,'大阪城公園',NULL,'https://www.osakacastle.net/','2026-06-26 10:00:00','2026-06-26 11:20:00',12500,4800,9.38,'completed','2026-06-26 11:51:57','2026-06-26 11:51:57',NULL),(2,1,'海遊館',NULL,'https://www.kaiyukan.com/','2026-06-25 14:00:00','2026-06-25 15:10:00',9800,4200,8.40,'completed','2026-06-26 11:51:57','2026-06-26 11:51:57',NULL),(3,2,'中之島公園',NULL,'https://www.osakapark140526.osgf.or.jp/nakanoshima/','2026-06-26 08:30:00',NULL,NULL,NULL,NULL,'active','2026-06-26 11:51:57','2026-07-03 11:25:37','2026-07-03 11:25:37'),(4,1,'',NULL,NULL,'2026-07-03 11:52:22','2026-07-03 11:52:32',NULL,NULL,NULL,'completed','2026-07-03 11:52:22','2026-07-03 11:57:25','2026-07-03 11:57:25'),(5,1,'株式会社weed',NULL,NULL,'2026-07-03 13:10:46','2026-07-03 13:11:50',NULL,NULL,NULL,'completed','2026-07-03 13:10:46','2026-07-03 13:11:50',NULL),(6,1,';',NULL,NULL,'2026-07-05 21:11:51','2026-07-05 21:15:19',NULL,NULL,NULL,'completed','2026-07-05 21:11:51','2026-07-05 21:15:19',NULL);
/*!40000 ALTER TABLE `trip_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `user_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `firebase_uid` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `display_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `photo_url` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `uq_users_firebase_uid` (`firebase_uid`),
  KEY `idx_users_deleted_at` (`deleted_at`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'firebase_uid_dummy_001','testuser1@example.com','テストユーザー1','https://example.com/images/user1.png','2026-06-26 11:51:47','2026-06-26 11:51:47',NULL),(2,'firebase_uid_dummy_002','testuser2@example.com','テストユーザー2','https://example.com/images/user2.png','2026-06-26 11:51:47','2026-06-26 11:51:47',NULL),(3,'e6jzCHkYLHMJDYOaVzXWMfcR7ax2','tk196vvv@gmail.com','あああ','https://lh3.googleusercontent.com/a/ACg8ocJa93DCvrd3ME9OB-j5ecjNlq4dcTDrD732P1vvwmPmQVdFuQ=s96-c','2026-07-07 23:15:55','2026-07-07 23:15:55',NULL);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_settings`
--

DROP TABLE IF EXISTS `user_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_settings` (
  `user_id` bigint unsigned NOT NULL,
  `include_visited_places` tinyint(1) NOT NULL DEFAULT '0',
  `voice_guidance_enabled` tinyint(1) NOT NULL DEFAULT '1',
  `keep_screen_awake` tinyint(1) NOT NULL DEFAULT '1',
  `auto_reroute_enabled` tinyint(1) NOT NULL DEFAULT '1',
  `map_type` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'normal',
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  CONSTRAINT `fk_user_settings_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-07-09 11:22:46
