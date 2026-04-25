USE haianhlearn_db;

CREATE INDEX idx_courses_course_name
    ON courses(course_name);

CREATE INDEX idx_enrollments_course_status
    ON enrollments(course_id, status);

CREATE INDEX idx_assessmentattempts_learner_attempt_date
    ON assessmentattempts(learner_id, attempt_date);

CREATE INDEX idx_auditlogs_table_time
    ON auditlogs(table_name, action_time);