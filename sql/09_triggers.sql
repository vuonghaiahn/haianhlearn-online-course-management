USE haianhlearn_db;

DROP TRIGGER IF EXISTS trg_enrollments_after_insert_audit;
DROP TRIGGER IF EXISTS trg_assessmentattempts_before_insert_set_pass;
DROP TRIGGER IF EXISTS trg_assessmentattempts_after_insert_handle_completion;
DROP TRIGGER IF EXISTS trg_learnerlectureprogress_after_update_handle_completion;

DELIMITER $$

-- 1. Log khi learner enroll course
CREATE TRIGGER trg_enrollments_after_insert_audit
AFTER INSERT ON enrollments
FOR EACH ROW
BEGIN
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
END$$

-- 2. Tự động set is_passed trước khi insert attempt
CREATE TRIGGER trg_assessmentattempts_before_insert_set_pass
BEFORE INSERT ON assessmentattempts
FOR EACH ROW
BEGIN
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
END$$

-- 3. Sau khi insert attempt, nếu đủ điều kiện thì complete enrollment + cấp certificate
CREATE TRIGGER trg_assessmentattempts_after_insert_handle_completion
AFTER INSERT ON assessmentattempts
FOR EACH ROW
BEGIN
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
END$$

-- 4. Sau khi learner complete lecture, nếu đã pass assessment và đủ lecture thì complete enrollment + cấp certificate
CREATE TRIGGER trg_learnerlectureprogress_after_update_handle_completion
AFTER UPDATE ON learnerlectureprogress
FOR EACH ROW
BEGIN
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
END$$

DELIMITER ;