USE haianhlearn_db;

DROP PROCEDURE IF EXISTS sp_register_learner_account;
DROP PROCEDURE IF EXISTS sp_enroll_learner_in_course;
DROP PROCEDURE IF EXISTS sp_generate_completion_summary;

DELIMITER $$

-- 1. Đăng ký learner account
CREATE PROCEDURE sp_register_learner_account (
    IN p_learner_name VARCHAR(100),
    IN p_email VARCHAR(100),
    IN p_phone_number VARCHAR(20),
    IN p_username VARCHAR(50),
    IN p_password_hash VARCHAR(255)
)
BEGIN
    DECLARE v_learner_id INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF EXISTS (
        SELECT 1
        FROM learners
        WHERE email = p_email
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email already exists.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM useraccounts
        WHERE username = p_username
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Username already exists.';
    END IF;

    START TRANSACTION;

    INSERT INTO learners (
        learner_name,
        email,
        phone_number,
        created_at
    )
    VALUES (
        p_learner_name,
        p_email,
        p_phone_number,
        NOW()
    );

    SET v_learner_id = LAST_INSERT_ID();

    INSERT INTO useraccounts (
        username,
        password_hash,
        role,
        learner_id,
        instructor_id,
        is_active,
        created_at
    )
    VALUES (
        p_username,
        p_password_hash,
        'learner',
        v_learner_id,
        NULL,
        1,
        NOW()
    );

    COMMIT;
END$$

-- 2. Enroll learner vào course
CREATE PROCEDURE sp_enroll_learner_in_course (
    IN p_learner_id INT,
    IN p_course_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM learners
        WHERE learner_id = p_learner_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Learner does not exist.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM courses
        WHERE course_id = p_course_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Course does not exist.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM enrollments
        WHERE learner_id = p_learner_id
          AND course_id = p_course_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Learner already enrolled in this course.';
    END IF;

    START TRANSACTION;

    INSERT INTO enrollments (
        learner_id,
        course_id,
        enrollment_date,
        status
    )
    VALUES (
        p_learner_id,
        p_course_id,
        CURDATE(),
        'enrolled'
    );

    -- Tạo progress record mặc định cho toàn bộ lecture của course
    INSERT INTO learnerlectureprogress (
        learner_id,
        lecture_id,
        is_completed,
        completed_at
    )
    SELECT
        p_learner_id,
        lec.lecture_id,
        0,
        NULL
    FROM lectures lec
    WHERE lec.course_id = p_course_id;

    COMMIT;
END$$

-- 3. Tạo completion summary cho learner trong một course
CREATE PROCEDURE sp_generate_completion_summary (
    IN p_learner_id INT,
    IN p_course_id INT
)
BEGIN
    SELECT
        l.learner_id,
        l.learner_name,
        c.course_id,
        c.course_name,
        COUNT(DISTINCT lec.lecture_id) AS total_lectures,
        COUNT(DISTINCT CASE WHEN llp.is_completed = 1 THEN lec.lecture_id END) AS completed_lectures,
        ROUND(
            CASE
                WHEN COUNT(DISTINCT lec.lecture_id) = 0 THEN 0
                ELSE COUNT(DISTINCT CASE WHEN llp.is_completed = 1 THEN lec.lecture_id END) * 100.0
                     / COUNT(DISTINCT lec.lecture_id)
            END
        , 2) AS completion_percentage,
        COALESCE(MAX(aa.score), 0) AS best_assessment_score,
        CASE
            WHEN MAX(CASE WHEN aa.is_passed = 1 THEN 1 ELSE 0 END) = 1 THEN 'Yes'
            ELSE 'No'
        END AS passed_assessment,
        e.status AS enrollment_status,
        CASE
            WHEN MAX(cert.certificate_id) IS NULL THEN 'No'
            ELSE 'Yes'
        END AS has_certificate
    FROM enrollments e
    JOIN learners l
        ON e.learner_id = l.learner_id
    JOIN courses c
        ON e.course_id = c.course_id
    LEFT JOIN lectures lec
        ON lec.course_id = c.course_id
    LEFT JOIN learnerlectureprogress llp
        ON llp.learner_id = l.learner_id
       AND llp.lecture_id = lec.lecture_id
       AND llp.is_completed = 1
    LEFT JOIN courseassessments ca
        ON ca.course_id = c.course_id
    LEFT JOIN assessmentattempts aa
        ON aa.assessment_id = ca.assessment_id
       AND aa.learner_id = l.learner_id
    LEFT JOIN certificates cert
        ON cert.learner_id = l.learner_id
       AND cert.course_id = c.course_id
    WHERE e.learner_id = p_learner_id
      AND e.course_id = p_course_id
    GROUP BY
        l.learner_id,
        l.learner_name,
        c.course_id,
        c.course_name,
        e.status;
END$$

DELIMITER ;