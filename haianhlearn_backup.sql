-- MySQL dump 10.13  Distrib 8.0.44, for Win64 (x86_64)
--
-- Host: localhost    Database: haianhlearn_db
-- ------------------------------------------------------
-- Server version	8.0.44

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
-- Table structure for table `assessmentattempts`
--

DROP TABLE IF EXISTS `assessmentattempts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `assessmentattempts` (
  `attempt_id` int NOT NULL AUTO_INCREMENT,
  `assessment_id` int NOT NULL,
  `learner_id` int NOT NULL,
  `score` decimal(5,2) NOT NULL,
  `attempt_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_passed` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`attempt_id`),
  KEY `fk_assessmentattempts_assessment` (`assessment_id`),
  KEY `idx_assessmentattempts_learner_attempt_date` (`learner_id`,`attempt_date`),
  CONSTRAINT `fk_assessmentattempts_assessment` FOREIGN KEY (`assessment_id`) REFERENCES `courseassessments` (`assessment_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_assessmentattempts_learner` FOREIGN KEY (`learner_id`) REFERENCES `learners` (`learner_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `chk_assessmentattempts_score` CHECK (((`score` >= 0) and (`score` <= 100)))
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `assessmentattempts`
--

LOCK TABLES `assessmentattempts` WRITE;
/*!40000 ALTER TABLE `assessmentattempts` DISABLE KEYS */;
INSERT INTO `assessmentattempts` VALUES (1,1,1,85.00,'2026-04-14 08:30:00',1),(2,3,1,92.00,'2026-04-14 09:00:00',1),(3,2,2,78.00,'2026-04-14 09:30:00',1),(4,5,3,88.00,'2026-04-14 10:00:00',1),(5,4,4,74.00,'2026-04-14 10:30:00',1),(6,1,3,60.00,'2026-04-14 11:00:00',0),(7,2,5,65.00,'2026-04-14 11:30:00',0),(8,5,5,68.00,'2026-04-14 12:00:00',0),(9,2,6,90.00,'2026-04-22 21:54:35',1);
/*!40000 ALTER TABLE `assessmentattempts` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_assessmentattempts_before_insert_set_pass` BEFORE INSERT ON `assessmentattempts` FOR EACH ROW BEGIN
    DECLARE v_passing_score INT DEFAULT 70;

    SELECT passing_score
    INTO v_passing_score
    FROM courseassessments
    WHERE assessment_id = NEW.assessment_id;

    IF NEW.score >= v_passing_score THEN
        SET NEW.is_passed = 1;
    ELSE
        SET NEW.is_passed = 0;
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_assessmentattempts_after_insert_handle_completion` AFTER INSERT ON `assessmentattempts` FOR EACH ROW BEGIN
    DECLARE v_course_id INT;
    DECLARE v_total_lectures INT DEFAULT 0;
    DECLARE v_completed_lectures INT DEFAULT 0;

    SELECT course_id
    INTO v_course_id
    FROM courseassessments
    WHERE assessment_id = NEW.assessment_id;

    INSERT INTO auditlogs (
        action_type,
        table_name,
        reference_id,
        action_time,
        description
    )
    VALUES (
        'INSERT',
        'assessmentattempts',
        NEW.attempt_id,
        NOW(),
        CONCAT('Learner ID ', NEW.learner_id,
               ' attempted Assessment ID ', NEW.assessment_id,
               ' with score ', NEW.score, '.')
    );

    IF NEW.is_passed = 1 THEN
        SELECT COUNT(*)
        INTO v_total_lectures
        FROM lectures
        WHERE course_id = v_course_id;

        SELECT COUNT(*)
        INTO v_completed_lectures
        FROM learnerlectureprogress llp
        JOIN lectures lec
            ON llp.lecture_id = lec.lecture_id
        WHERE llp.learner_id = NEW.learner_id
          AND lec.course_id = v_course_id
          AND llp.is_completed = 1;

        IF v_total_lectures > 0 AND v_total_lectures = v_completed_lectures THEN
            UPDATE enrollments
            SET status = 'completed'
            WHERE learner_id = NEW.learner_id
              AND course_id = v_course_id;

            IF NOT EXISTS (
                SELECT 1
                FROM certificates
                WHERE learner_id = NEW.learner_id
                  AND course_id = v_course_id
            ) THEN
                INSERT INTO certificates (
                    learner_id,
                    course_id,
                    issue_date,
                    certificate_code
                )
                VALUES (
                    NEW.learner_id,
                    v_course_id,
                    NOW(),
                    CONCAT('CERT-', LEFT(REPLACE(UUID(), '-', ''), 16))
                );

                INSERT INTO auditlogs (
                    action_type,
                    table_name,
                    reference_id,
                    action_time,
                    description
                )
                VALUES (
                    'INSERT',
                    'certificates',
                    LAST_INSERT_ID(),
                    NOW(),
                    CONCAT('Certificate issued to Learner ID ',
                           NEW.learner_id,
                           ' for Course ID ',
                           v_course_id, '.')
                );
            END IF;
        END IF;
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `auditlogs`
--

DROP TABLE IF EXISTS `auditlogs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `auditlogs` (
  `log_id` int NOT NULL AUTO_INCREMENT,
  `action_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `table_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `reference_id` int NOT NULL,
  `action_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `description` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`log_id`),
  KEY `idx_auditlogs_table_time` (`table_name`,`action_time`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auditlogs`
--

LOCK TABLES `auditlogs` WRITE;
/*!40000 ALTER TABLE `auditlogs` DISABLE KEYS */;
INSERT INTO `auditlogs` VALUES (1,'INSERT','enrollments',1,'2026-04-05 10:00:00','Learner Alice Nguyen enrolled in Introduction to SQL.'),(2,'INSERT','enrollments',3,'2026-04-06 10:10:00','Learner Binh Tran enrolled in Database Design Fundamentals.'),(3,'UPDATE','learnerlectureprogress',2,'2026-04-11 09:20:00','Alice Nguyen completed lecture 2 of Introduction to SQL.'),(4,'INSERT','assessmentattempts',1,'2026-04-14 08:30:00','Alice Nguyen passed the final assessment for Introduction to SQL.'),(5,'INSERT','certificates',1,'2026-04-15 09:00:00','Certificate issued to Alice Nguyen for Introduction to SQL.'),(6,'INSERT','certificates',5,'2026-04-15 09:40:00','Certificate issued to David Le for Web Development Basics.'),(7,'INSERT','enrollments',12,'2026-04-22 21:54:22','Learner ID 6 enrolled in Course ID 2.'),(8,'UPDATE','learnerlectureprogress',14,'2026-04-22 21:54:35','Learner ID 6 completed Lecture ID 3.'),(9,'UPDATE','learnerlectureprogress',15,'2026-04-22 21:54:35','Learner ID 6 completed Lecture ID 4.'),(10,'INSERT','assessmentattempts',9,'2026-04-22 21:54:35','Learner ID 6 attempted Assessment ID 2 with score 90.00.'),(11,'INSERT','certificates',6,'2026-04-22 21:54:35','Certificate issued to Learner ID 6 for Course ID 2.');
/*!40000 ALTER TABLE `auditlogs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `certificates`
--

DROP TABLE IF EXISTS `certificates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `certificates` (
  `certificate_id` int NOT NULL AUTO_INCREMENT,
  `learner_id` int NOT NULL,
  `course_id` int NOT NULL,
  `issue_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `certificate_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`certificate_id`),
  UNIQUE KEY `certificate_code` (`certificate_code`),
  UNIQUE KEY `uq_certificates_learner_course` (`learner_id`,`course_id`),
  KEY `fk_certificates_course` (`course_id`),
  CONSTRAINT `fk_certificates_course` FOREIGN KEY (`course_id`) REFERENCES `courses` (`course_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_certificates_learner` FOREIGN KEY (`learner_id`) REFERENCES `learners` (`learner_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `certificates`
--

LOCK TABLES `certificates` WRITE;
/*!40000 ALTER TABLE `certificates` DISABLE KEYS */;
INSERT INTO `certificates` VALUES (1,1,1,'2026-04-15 09:00:00','CERT-SQL-ALICE-001'),(2,1,3,'2026-04-15 09:10:00','CERT-PY-ALICE-002'),(3,2,2,'2026-04-15 09:20:00','CERT-DB-BINH-003'),(4,3,5,'2026-04-15 09:30:00','CERT-BI-CHLOE-004'),(5,4,4,'2026-04-15 09:40:00','CERT-WEB-DAVID-005'),(6,6,2,'2026-04-22 21:54:35','CERT-2db5ad9b3e5b11f1');
/*!40000 ALTER TABLE `certificates` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `courseassessments`
--

DROP TABLE IF EXISTS `courseassessments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `courseassessments` (
  `assessment_id` int NOT NULL AUTO_INCREMENT,
  `course_id` int NOT NULL,
  `title` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `total_score` int NOT NULL DEFAULT '100',
  `passing_score` int NOT NULL DEFAULT '70',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`assessment_id`),
  UNIQUE KEY `course_id` (`course_id`),
  CONSTRAINT `fk_courseassessments_course` FOREIGN KEY (`course_id`) REFERENCES `courses` (`course_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `chk_courseassessments_score` CHECK (((`total_score` > 0) and (`passing_score` >= 0) and (`passing_score` <= `total_score`)))
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `courseassessments`
--

LOCK TABLES `courseassessments` WRITE;
/*!40000 ALTER TABLE `courseassessments` DISABLE KEYS */;
INSERT INTO `courseassessments` VALUES (1,1,'Final Quiz: Introduction to SQL',100,70,'2026-04-10 08:00:00'),(2,2,'Final Quiz: Database Design Fundamentals',100,70,'2026-04-10 08:10:00'),(3,3,'Final Quiz: Python for Data Management',100,70,'2026-04-10 08:20:00'),(4,4,'Final Quiz: Web Development Basics',100,70,'2026-04-10 08:30:00'),(5,5,'Final Quiz: Data Visualization with BI Tools',100,70,'2026-04-10 08:40:00');
/*!40000 ALTER TABLE `courseassessments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `courses`
--

DROP TABLE IF EXISTS `courses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `courses` (
  `course_id` int NOT NULL AUTO_INCREMENT,
  `course_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `instructor_id` int NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`course_id`),
  KEY `fk_courses_instructor` (`instructor_id`),
  KEY `idx_courses_course_name` (`course_name`),
  CONSTRAINT `fk_courses_instructor` FOREIGN KEY (`instructor_id`) REFERENCES `instructors` (`instructor_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `courses`
--

LOCK TABLES `courses` WRITE;
/*!40000 ALTER TABLE `courses` DISABLE KEYS */;
INSERT INTO `courses` VALUES (1,'Introduction to SQL','Learn basic SQL queries, filtering, sorting, and data retrieval techniques.',1,'2026-04-02 08:00:00'),(2,'Database Design Fundamentals','Study ER diagrams, normalization, keys, and relationship modeling.',2,'2026-04-02 08:10:00'),(3,'Python for Data Management','Use Python to connect to databases and perform CRUD operations.',3,'2026-04-02 08:20:00'),(4,'Web Development Basics','Understand the basics of HTML, CSS, and Flask-based routing.',4,'2026-04-02 08:30:00'),(5,'Data Visualization with BI Tools','Create dashboards and reports using practical business intelligence concepts.',5,'2026-04-02 08:40:00');
/*!40000 ALTER TABLE `courses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `enrollments`
--

DROP TABLE IF EXISTS `enrollments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `enrollments` (
  `enrollment_id` int NOT NULL AUTO_INCREMENT,
  `learner_id` int NOT NULL,
  `course_id` int NOT NULL,
  `enrollment_date` date NOT NULL,
  `status` enum('enrolled','completed','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'enrolled',
  PRIMARY KEY (`enrollment_id`),
  UNIQUE KEY `uq_enrollments_learner_course` (`learner_id`,`course_id`),
  KEY `idx_enrollments_course_status` (`course_id`,`status`),
  CONSTRAINT `fk_enrollments_course` FOREIGN KEY (`course_id`) REFERENCES `courses` (`course_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_enrollments_learner` FOREIGN KEY (`learner_id`) REFERENCES `learners` (`learner_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `enrollments`
--

LOCK TABLES `enrollments` WRITE;
/*!40000 ALTER TABLE `enrollments` DISABLE KEYS */;
INSERT INTO `enrollments` VALUES (1,1,1,'2026-04-05','completed'),(2,1,3,'2026-04-05','completed'),(3,2,2,'2026-04-06','completed'),(4,2,4,'2026-04-06','enrolled'),(5,3,5,'2026-04-07','completed'),(6,3,1,'2026-04-07','enrolled'),(7,4,4,'2026-04-08','completed'),(8,5,2,'2026-04-08','enrolled'),(9,5,5,'2026-04-08','enrolled'),(10,4,3,'2026-04-09','enrolled'),(11,5,1,'2026-04-22','enrolled'),(12,6,2,'2026-04-22','completed');
/*!40000 ALTER TABLE `enrollments` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_enrollments_after_insert_audit` AFTER INSERT ON `enrollments` FOR EACH ROW BEGIN
    INSERT INTO auditlogs (
        action_type,
        table_name,
        reference_id,
        action_time,
        description
    )
    VALUES (
        'INSERT',
        'enrollments',
        NEW.enrollment_id,
        NOW(),
        CONCAT('Learner ID ', NEW.learner_id,
               ' enrolled in Course ID ', NEW.course_id, '.')
    );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `instructors`
--

DROP TABLE IF EXISTS `instructors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `instructors` (
  `instructor_id` int NOT NULL AUTO_INCREMENT,
  `instructor_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expertise` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`instructor_id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `instructors`
--

LOCK TABLES `instructors` WRITE;
/*!40000 ALTER TABLE `instructors` DISABLE KEYS */;
INSERT INTO `instructors` VALUES (1,'Dr. Anna Vo','SQL and Data Modeling','anna.vo@haianhlearn.com','2026-04-01 10:00:00'),(2,'Mr. Brian Dang','Database Design','brian.dang@haianhlearn.com','2026-04-01 10:05:00'),(3,'Ms. Clara Nguyen','Python Data Processing','clara.nguyen@haianhlearn.com','2026-04-01 10:10:00'),(4,'Dr. Daniel Pham','Web Development','daniel.pham@haianhlearn.com','2026-04-01 10:15:00'),(5,'Ms. Ella Tran','Business Intelligence','ella.tran@haianhlearn.com','2026-04-01 10:20:00');
/*!40000 ALTER TABLE `instructors` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `learnerlectureprogress`
--

DROP TABLE IF EXISTS `learnerlectureprogress`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `learnerlectureprogress` (
  `progress_id` int NOT NULL AUTO_INCREMENT,
  `learner_id` int NOT NULL,
  `lecture_id` int NOT NULL,
  `is_completed` tinyint(1) NOT NULL DEFAULT '0',
  `completed_at` datetime DEFAULT NULL,
  PRIMARY KEY (`progress_id`),
  UNIQUE KEY `uq_progress_learner_lecture` (`learner_id`,`lecture_id`),
  KEY `fk_progress_lecture` (`lecture_id`),
  CONSTRAINT `fk_progress_learner` FOREIGN KEY (`learner_id`) REFERENCES `learners` (`learner_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_progress_lecture` FOREIGN KEY (`lecture_id`) REFERENCES `lectures` (`lecture_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `learnerlectureprogress`
--

LOCK TABLES `learnerlectureprogress` WRITE;
/*!40000 ALTER TABLE `learnerlectureprogress` DISABLE KEYS */;
INSERT INTO `learnerlectureprogress` VALUES (1,1,1,1,'2026-04-11 09:00:00'),(2,1,2,1,'2026-04-11 09:20:00'),(3,1,5,1,'2026-04-11 10:00:00'),(4,1,6,1,'2026-04-11 10:25:00'),(5,2,3,1,'2026-04-12 09:00:00'),(6,2,4,1,'2026-04-12 09:30:00'),(7,3,9,1,'2026-04-12 10:00:00'),(8,3,10,1,'2026-04-12 10:35:00'),(9,4,7,1,'2026-04-13 09:00:00'),(10,4,8,1,'2026-04-13 09:25:00'),(11,5,1,0,NULL),(12,5,2,0,NULL),(14,6,3,1,'2026-04-22 21:54:35'),(15,6,4,1,'2026-04-22 21:54:35');
/*!40000 ALTER TABLE `learnerlectureprogress` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_learnerlectureprogress_after_update_handle_completion` AFTER UPDATE ON `learnerlectureprogress` FOR EACH ROW BEGIN
    DECLARE v_course_id INT;
    DECLARE v_total_lectures INT DEFAULT 0;
    DECLARE v_completed_lectures INT DEFAULT 0;
    DECLARE v_has_passed INT DEFAULT 0;

    IF NEW.is_completed = 1 AND OLD.is_completed = 0 THEN

        SELECT course_id
        INTO v_course_id
        FROM lectures
        WHERE lecture_id = NEW.lecture_id;

        INSERT INTO auditlogs (
            action_type,
            table_name,
            reference_id,
            action_time,
            description
        )
        VALUES (
            'UPDATE',
            'learnerlectureprogress',
            NEW.progress_id,
            NOW(),
            CONCAT('Learner ID ', NEW.learner_id,
                   ' completed Lecture ID ', NEW.lecture_id, '.')
        );

        SELECT COUNT(*)
        INTO v_total_lectures
        FROM lectures
        WHERE course_id = v_course_id;

        SELECT COUNT(*)
        INTO v_completed_lectures
        FROM learnerlectureprogress llp
        JOIN lectures lec
            ON llp.lecture_id = lec.lecture_id
        WHERE llp.learner_id = NEW.learner_id
          AND lec.course_id = v_course_id
          AND llp.is_completed = 1;

        SELECT COUNT(*)
        INTO v_has_passed
        FROM assessmentattempts aa
        JOIN courseassessments ca
            ON aa.assessment_id = ca.assessment_id
        WHERE aa.learner_id = NEW.learner_id
          AND ca.course_id = v_course_id
          AND aa.is_passed = 1;

        IF v_total_lectures > 0
           AND v_total_lectures = v_completed_lectures
           AND v_has_passed > 0 THEN

            UPDATE enrollments
            SET status = 'completed'
            WHERE learner_id = NEW.learner_id
              AND course_id = v_course_id;

            IF NOT EXISTS (
                SELECT 1
                FROM certificates
                WHERE learner_id = NEW.learner_id
                  AND course_id = v_course_id
            ) THEN
                INSERT INTO certificates (
                    learner_id,
                    course_id,
                    issue_date,
                    certificate_code
                )
                VALUES (
                    NEW.learner_id,
                    v_course_id,
                    NOW(),
                    CONCAT('CERT-', LEFT(REPLACE(UUID(), '-', ''), 16))
                );

                INSERT INTO auditlogs (
                    action_type,
                    table_name,
                    reference_id,
                    action_time,
                    description
                )
                VALUES (
                    'INSERT',
                    'certificates',
                    LAST_INSERT_ID(),
                    NOW(),
                    CONCAT('Certificate issued to Learner ID ',
                           NEW.learner_id,
                           ' for Course ID ',
                           v_course_id, '.')
                );
            END IF;
        END IF;
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `learners`
--

DROP TABLE IF EXISTS `learners`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `learners` (
  `learner_id` int NOT NULL AUTO_INCREMENT,
  `learner_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone_number` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`learner_id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `learners`
--

LOCK TABLES `learners` WRITE;
/*!40000 ALTER TABLE `learners` DISABLE KEYS */;
INSERT INTO `learners` VALUES (1,'Alice Nguyen','alice.nguyen@haianhlearn.com','0901888888','2026-04-01 09:00:00'),(2,'Binh Tran','binh.tran@haianhlearn.com','0901000002','2026-04-01 09:05:00'),(3,'Chloe Pham','chloe.pham@haianhlearn.com','0901000003','2026-04-01 09:10:00'),(4,'David Le','david.le@haianhlearn.com','0901000004','2026-04-01 09:15:00'),(5,'Emma Hoang','emma.hoang@haianhlearn.com','0901000005','2026-04-01 09:20:00'),(6,'Hana Nguyen','hana.nguyen@haianhlearn.com','0901999999','2026-04-22 21:52:32'),(7,'Minh Vu','minh.vu@haianhlearn.com','0901888888','2026-04-22 21:54:22');
/*!40000 ALTER TABLE `learners` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lectures`
--

DROP TABLE IF EXISTS `lectures`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `lectures` (
  `lecture_id` int NOT NULL AUTO_INCREMENT,
  `course_id` int NOT NULL,
  `title` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `content` text COLLATE utf8mb4_unicode_ci,
  `lecture_order` int NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`lecture_id`),
  UNIQUE KEY `uq_lectures_course_order` (`course_id`,`lecture_order`),
  CONSTRAINT `fk_lectures_course` FOREIGN KEY (`course_id`) REFERENCES `courses` (`course_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lectures`
--

LOCK TABLES `lectures` WRITE;
/*!40000 ALTER TABLE `lectures` DISABLE KEYS */;
INSERT INTO `lectures` VALUES (1,1,'SQL Basics','Introduction to SELECT, FROM, and WHERE clauses.',1,'2026-04-03 09:00:00'),(2,1,'Filtering and Sorting Data','Using ORDER BY, LIMIT, and conditional filtering.',2,'2026-04-03 09:15:00'),(3,2,'Understanding ER Models','Entities, attributes, and relationships in database design.',1,'2026-04-03 09:30:00'),(4,2,'Normalization Essentials','First, second, and third normal form with examples.',2,'2026-04-03 09:45:00'),(5,3,'Python Database Connectivity','Connecting Python applications to MySQL databases.',1,'2026-04-03 10:00:00'),(6,3,'CRUD Operations with Python','Create, read, update, and delete data using Python.',2,'2026-04-03 10:15:00'),(7,4,'HTML and CSS Foundations','Building structured and styled web pages.',1,'2026-04-03 10:30:00'),(8,4,'Flask Routing Basics','Creating routes and rendering templates in Flask.',2,'2026-04-03 10:45:00'),(9,5,'Dashboard Design Principles','How to organize charts and indicators effectively.',1,'2026-04-03 11:00:00'),(10,5,'Building Interactive Reports','Presenting data insights using simple reporting tools.',2,'2026-04-03 11:15:00');
/*!40000 ALTER TABLE `lectures` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `useraccounts`
--

DROP TABLE IF EXISTS `useraccounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `useraccounts` (
  `account_id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `role` enum('admin','instructor','learner') COLLATE utf8mb4_unicode_ci NOT NULL,
  `learner_id` int DEFAULT NULL,
  `instructor_id` int DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`account_id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `learner_id` (`learner_id`),
  UNIQUE KEY `instructor_id` (`instructor_id`),
  CONSTRAINT `fk_useraccounts_instructor` FOREIGN KEY (`instructor_id`) REFERENCES `instructors` (`instructor_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_useraccounts_learner` FOREIGN KEY (`learner_id`) REFERENCES `learners` (`learner_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `useraccounts`
--

LOCK TABLES `useraccounts` WRITE;
/*!40000 ALTER TABLE `useraccounts` DISABLE KEYS */;
INSERT INTO `useraccounts` VALUES (1,'admin01','pbkdf2_demo_admin_001','admin',NULL,NULL,1,'2026-04-16 08:00:00'),(2,'alice.learn','pbkdf2_demo_learner_001','learner',1,NULL,1,'2026-04-16 08:10:00'),(3,'binh.learn','pbkdf2_demo_learner_002','learner',2,NULL,1,'2026-04-16 08:20:00'),(4,'chloe.learn','pbkdf2_demo_learner_003','learner',3,NULL,1,'2026-04-16 08:30:00'),(5,'anna.instructor','pbkdf2_demo_instructor_001','instructor',NULL,1,1,'2026-04-16 08:40:00'),(6,'brian.instructor','pbkdf2_demo_instructor_002','instructor',NULL,2,1,'2026-04-16 08:50:00'),(7,'daniel.instructor','pbkdf2_demo_instructor_003','instructor',NULL,4,1,'2026-04-16 09:00:00'),(8,'hana.learn','pbkdf2_demo_hana_001','learner',6,NULL,1,'2026-04-22 21:52:32'),(9,'minh.learn','pbkdf2_demo_minh_001','learner',7,NULL,1,'2026-04-22 21:54:22');
/*!40000 ALTER TABLE `useraccounts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `vw_admin_dashboard_summary`
--

DROP TABLE IF EXISTS `vw_admin_dashboard_summary`;
/*!50001 DROP VIEW IF EXISTS `vw_admin_dashboard_summary`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_admin_dashboard_summary` AS SELECT 
 1 AS `total_learners`,
 1 AS `total_instructors`,
 1 AS `total_courses`,
 1 AS `total_lectures`,
 1 AS `total_enrollments`,
 1 AS `total_certificates`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_instructor_student_progress`
--

DROP TABLE IF EXISTS `vw_instructor_student_progress`;
/*!50001 DROP VIEW IF EXISTS `vw_instructor_student_progress`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_instructor_student_progress` AS SELECT 
 1 AS `instructor_id`,
 1 AS `instructor_name`,
 1 AS `course_id`,
 1 AS `course_name`,
 1 AS `learner_id`,
 1 AS `learner_name`,
 1 AS `completed_lectures`,
 1 AS `total_lectures`,
 1 AS `completion_percentage`,
 1 AS `enrollment_status`,
 1 AS `best_assessment_score`,
 1 AS `has_certificate`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_instructor_teaching_load`
--

DROP TABLE IF EXISTS `vw_instructor_teaching_load`;
/*!50001 DROP VIEW IF EXISTS `vw_instructor_teaching_load`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_instructor_teaching_load` AS SELECT 
 1 AS `instructor_id`,
 1 AS `instructor_name`,
 1 AS `course_id`,
 1 AS `course_name`,
 1 AS `total_enrolled_learners`,
 1 AS `total_completed_learners`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_learner_course_progress`
--

DROP TABLE IF EXISTS `vw_learner_course_progress`;
/*!50001 DROP VIEW IF EXISTS `vw_learner_course_progress`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_learner_course_progress` AS SELECT 
 1 AS `learner_id`,
 1 AS `learner_name`,
 1 AS `course_id`,
 1 AS `course_name`,
 1 AS `total_lectures`,
 1 AS `completed_lectures`,
 1 AS `completion_percentage`,
 1 AS `best_assessment_score`,
 1 AS `has_certificate`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_learner_enrolled_courses`
--

DROP TABLE IF EXISTS `vw_learner_enrolled_courses`;
/*!50001 DROP VIEW IF EXISTS `vw_learner_enrolled_courses`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_learner_enrolled_courses` AS SELECT 
 1 AS `enrollment_id`,
 1 AS `learner_id`,
 1 AS `learner_name`,
 1 AS `course_id`,
 1 AS `course_name`,
 1 AS `instructor_name`,
 1 AS `enrollment_date`,
 1 AS `status`*/;
SET character_set_client = @saved_cs_client;

--
-- Final view structure for view `vw_admin_dashboard_summary`
--

/*!50001 DROP VIEW IF EXISTS `vw_admin_dashboard_summary`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_admin_dashboard_summary` AS select (select count(0) from `learners`) AS `total_learners`,(select count(0) from `instructors`) AS `total_instructors`,(select count(0) from `courses`) AS `total_courses`,(select count(0) from `lectures`) AS `total_lectures`,(select count(0) from `enrollments`) AS `total_enrollments`,(select count(0) from `certificates`) AS `total_certificates` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_instructor_student_progress`
--

/*!50001 DROP VIEW IF EXISTS `vw_instructor_student_progress`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_instructor_student_progress` AS select `i`.`instructor_id` AS `instructor_id`,`i`.`instructor_name` AS `instructor_name`,`c`.`course_id` AS `course_id`,`c`.`course_name` AS `course_name`,`l`.`learner_id` AS `learner_id`,`l`.`learner_name` AS `learner_name`,`v`.`completed_lectures` AS `completed_lectures`,`v`.`total_lectures` AS `total_lectures`,`v`.`completion_percentage` AS `completion_percentage`,`e`.`status` AS `enrollment_status`,`v`.`best_assessment_score` AS `best_assessment_score`,`v`.`has_certificate` AS `has_certificate` from ((((`instructors` `i` join `courses` `c` on((`i`.`instructor_id` = `c`.`instructor_id`))) join `enrollments` `e` on((`c`.`course_id` = `e`.`course_id`))) join `learners` `l` on((`e`.`learner_id` = `l`.`learner_id`))) left join `vw_learner_course_progress` `v` on(((`v`.`learner_id` = `l`.`learner_id`) and (`v`.`course_id` = `c`.`course_id`)))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_instructor_teaching_load`
--

/*!50001 DROP VIEW IF EXISTS `vw_instructor_teaching_load`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_instructor_teaching_load` AS select `i`.`instructor_id` AS `instructor_id`,`i`.`instructor_name` AS `instructor_name`,`c`.`course_id` AS `course_id`,`c`.`course_name` AS `course_name`,count(distinct `e`.`learner_id`) AS `total_enrolled_learners`,count(distinct (case when (`e`.`status` = 'completed') then `e`.`learner_id` end)) AS `total_completed_learners` from ((`instructors` `i` left join `courses` `c` on((`i`.`instructor_id` = `c`.`instructor_id`))) left join `enrollments` `e` on((`c`.`course_id` = `e`.`course_id`))) group by `i`.`instructor_id`,`i`.`instructor_name`,`c`.`course_id`,`c`.`course_name` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_learner_course_progress`
--

/*!50001 DROP VIEW IF EXISTS `vw_learner_course_progress`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_learner_course_progress` AS select `l`.`learner_id` AS `learner_id`,`l`.`learner_name` AS `learner_name`,`c`.`course_id` AS `course_id`,`c`.`course_name` AS `course_name`,count(distinct `lec`.`lecture_id`) AS `total_lectures`,count(distinct (case when (`llp`.`is_completed` = 1) then `lec`.`lecture_id` end)) AS `completed_lectures`,round((case when (count(distinct `lec`.`lecture_id`) = 0) then 0 else ((count(distinct (case when (`llp`.`is_completed` = 1) then `lec`.`lecture_id` end)) * 100.0) / count(distinct `lec`.`lecture_id`)) end),2) AS `completion_percentage`,coalesce(max(`aa`.`score`),0) AS `best_assessment_score`,(case when (max(`cert`.`certificate_id`) is null) then 'No' else 'Yes' end) AS `has_certificate` from (((((((`enrollments` `e` join `learners` `l` on((`e`.`learner_id` = `l`.`learner_id`))) join `courses` `c` on((`e`.`course_id` = `c`.`course_id`))) left join `lectures` `lec` on((`lec`.`course_id` = `c`.`course_id`))) left join `learnerlectureprogress` `llp` on(((`llp`.`learner_id` = `l`.`learner_id`) and (`llp`.`lecture_id` = `lec`.`lecture_id`) and (`llp`.`is_completed` = 1)))) left join `courseassessments` `ca` on((`ca`.`course_id` = `c`.`course_id`))) left join `assessmentattempts` `aa` on(((`aa`.`assessment_id` = `ca`.`assessment_id`) and (`aa`.`learner_id` = `l`.`learner_id`)))) left join `certificates` `cert` on(((`cert`.`learner_id` = `l`.`learner_id`) and (`cert`.`course_id` = `c`.`course_id`)))) group by `l`.`learner_id`,`l`.`learner_name`,`c`.`course_id`,`c`.`course_name` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_learner_enrolled_courses`
--

/*!50001 DROP VIEW IF EXISTS `vw_learner_enrolled_courses`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_learner_enrolled_courses` AS select `e`.`enrollment_id` AS `enrollment_id`,`l`.`learner_id` AS `learner_id`,`l`.`learner_name` AS `learner_name`,`c`.`course_id` AS `course_id`,`c`.`course_name` AS `course_name`,`i`.`instructor_name` AS `instructor_name`,`e`.`enrollment_date` AS `enrollment_date`,`e`.`status` AS `status` from (((`enrollments` `e` join `learners` `l` on((`e`.`learner_id` = `l`.`learner_id`))) join `courses` `c` on((`e`.`course_id` = `c`.`course_id`))) join `instructors` `i` on((`c`.`instructor_id` = `i`.`instructor_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-04-22 22:17:01
