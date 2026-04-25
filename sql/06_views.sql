USE haianhlearn_db;

DROP VIEW IF EXISTS vw_instructor_student_progress;
DROP VIEW IF EXISTS vw_instructor_teaching_load;
DROP VIEW IF EXISTS vw_admin_dashboard_summary;
DROP VIEW IF EXISTS vw_learner_course_progress;
DROP VIEW IF EXISTS vw_learner_enrolled_courses;

-- 1. Learner xem các course đã đăng ký
CREATE VIEW vw_learner_enrolled_courses AS
SELECT
    e.enrollment_id,
    l.learner_id,
    l.learner_name,
    c.course_id,
    c.course_name,
    i.instructor_name,
    e.enrollment_date,
    e.status
FROM enrollments e
JOIN learners l
    ON e.learner_id = l.learner_id
JOIN courses c
    ON e.course_id = c.course_id
JOIN instructors i
    ON c.instructor_id = i.instructor_id;

-- 2. Tiến độ học theo learner - course
CREATE VIEW vw_learner_course_progress AS
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
GROUP BY
    l.learner_id,
    l.learner_name,
    c.course_id,
    c.course_name;

-- 3. Teaching load của instructor
CREATE VIEW vw_instructor_teaching_load AS
SELECT
    i.instructor_id,
    i.instructor_name,
    c.course_id,
    c.course_name,
    COUNT(DISTINCT e.learner_id) AS total_enrolled_learners,
    COUNT(DISTINCT CASE WHEN e.status = 'completed' THEN e.learner_id END) AS total_completed_learners
FROM instructors i
LEFT JOIN courses c
    ON i.instructor_id = c.instructor_id
LEFT JOIN enrollments e
    ON c.course_id = e.course_id
GROUP BY
    i.instructor_id,
    i.instructor_name,
    c.course_id,
    c.course_name;

-- 4. Instructor xem tiến độ từng học viên trong course của mình
CREATE VIEW vw_instructor_student_progress AS
SELECT
    i.instructor_id,
    i.instructor_name,
    c.course_id,
    c.course_name,
    l.learner_id,
    l.learner_name,
    v.completed_lectures,
    v.total_lectures,
    v.completion_percentage,
    e.status AS enrollment_status,
    v.best_assessment_score,
    v.has_certificate
FROM instructors i
JOIN courses c
    ON i.instructor_id = c.instructor_id
JOIN enrollments e
    ON c.course_id = e.course_id
JOIN learners l
    ON e.learner_id = l.learner_id
LEFT JOIN vw_learner_course_progress v
    ON v.learner_id = l.learner_id
   AND v.course_id = c.course_id;

-- 5. Dashboard tổng quan cho admin
CREATE VIEW vw_admin_dashboard_summary AS
SELECT
    (SELECT COUNT(*) FROM learners) AS total_learners,
    (SELECT COUNT(*) FROM instructors) AS total_instructors,
    (SELECT COUNT(*) FROM courses) AS total_courses,
    (SELECT COUNT(*) FROM lectures) AS total_lectures,
    (SELECT COUNT(*) FROM enrollments) AS total_enrollments,
    (SELECT COUNT(*) FROM certificates) AS total_certificates;