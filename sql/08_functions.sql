USE haianhlearn_db;

DROP FUNCTION IF EXISTS fn_total_completed_lectures;
DROP FUNCTION IF EXISTS fn_completion_percentage;

DELIMITER $$

-- 1. Tổng số lecture learner đã hoàn thành trong một course
CREATE FUNCTION fn_total_completed_lectures (
    p_learner_id INT,
    p_course_id INT
)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_completed INT DEFAULT 0;

    SELECT COUNT(*)
    INTO v_completed
    FROM learnerlectureprogress llp
    JOIN lectures lec
        ON llp.lecture_id = lec.lecture_id
    WHERE llp.learner_id = p_learner_id
      AND lec.course_id = p_course_id
      AND llp.is_completed = 1;

    RETURN COALESCE(v_completed, 0);
END$$

-- 2. Tính phần trăm hoàn thành course
CREATE FUNCTION fn_completion_percentage (
    p_learner_id INT,
    p_course_id INT
)
RETURNS DECIMAL(5,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total INT DEFAULT 0;
    DECLARE v_completed INT DEFAULT 0;
    DECLARE v_percentage DECIMAL(5,2) DEFAULT 0;

    SELECT COUNT(*)
    INTO v_total
    FROM lectures
    WHERE course_id = p_course_id;

    SELECT COUNT(*)
    INTO v_completed
    FROM learnerlectureprogress llp
    JOIN lectures lec
        ON llp.lecture_id = lec.lecture_id
    WHERE llp.learner_id = p_learner_id
      AND lec.course_id = p_course_id
      AND llp.is_completed = 1;

    IF v_total = 0 THEN
        SET v_percentage = 0;
    ELSE
        SET v_percentage = ROUND((v_completed * 100.0) / v_total, 2);
    END IF;

    RETURN v_percentage;
END$$

DELIMITER ;