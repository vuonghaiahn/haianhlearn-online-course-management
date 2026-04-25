USE haianhlearn_db;

INSERT INTO learners
(learner_id, learner_name, email, phone_number, created_at)
VALUES
(1, 'Alice Nguyen', 'alice.nguyen@haianhlearn.com', '0901000001', '2026-04-01 09:00:00'),
(2, 'Binh Tran', 'binh.tran@haianhlearn.com', '0901000002', '2026-04-01 09:05:00'),
(3, 'Chloe Pham', 'chloe.pham@haianhlearn.com', '0901000003', '2026-04-01 09:10:00'),
(4, 'David Le', 'david.le@haianhlearn.com', '0901000004', '2026-04-01 09:15:00'),
(5, 'Emma Hoang', 'emma.hoang@haianhlearn.com', '0901000005', '2026-04-01 09:20:00');

INSERT INTO instructors
(instructor_id, instructor_name, expertise, email, created_at)
VALUES
(1, 'Dr. Anna Vo', 'SQL and Data Modeling', 'anna.vo@haianhlearn.com', '2026-04-01 10:00:00'),
(2, 'Mr. Brian Dang', 'Database Design', 'brian.dang@haianhlearn.com', '2026-04-01 10:05:00'),
(3, 'Ms. Clara Nguyen', 'Python Data Processing', 'clara.nguyen@haianhlearn.com', '2026-04-01 10:10:00'),
(4, 'Dr. Daniel Pham', 'Web Development', 'daniel.pham@haianhlearn.com', '2026-04-01 10:15:00'),
(5, 'Ms. Ella Tran', 'Business Intelligence', 'ella.tran@haianhlearn.com', '2026-04-01 10:20:00');

INSERT INTO courses
(course_id, course_name, description, instructor_id, created_at)
VALUES
(1, 'Introduction to SQL', 'Learn basic SQL queries, filtering, sorting, and data retrieval techniques.', 1, '2026-04-02 08:00:00'),
(2, 'Database Design Fundamentals', 'Study ER diagrams, normalization, keys, and relationship modeling.', 2, '2026-04-02 08:10:00'),
(3, 'Python for Data Management', 'Use Python to connect to databases and perform CRUD operations.', 3, '2026-04-02 08:20:00'),
(4, 'Web Development Basics', 'Understand the basics of HTML, CSS, and Flask-based routing.', 4, '2026-04-02 08:30:00'),
(5, 'Data Visualization with BI Tools', 'Create dashboards and reports using practical business intelligence concepts.', 5, '2026-04-02 08:40:00');

INSERT INTO lectures
(lecture_id, course_id, title, content, lecture_order, created_at)
VALUES
(1, 1, 'SQL Basics', 'Introduction to SELECT, FROM, and WHERE clauses.', 1, '2026-04-03 09:00:00'),
(2, 1, 'Filtering and Sorting Data', 'Using ORDER BY, LIMIT, and conditional filtering.', 2, '2026-04-03 09:15:00'),
(3, 2, 'Understanding ER Models', 'Entities, attributes, and relationships in database design.', 1, '2026-04-03 09:30:00'),
(4, 2, 'Normalization Essentials', 'First, second, and third normal form with examples.', 2, '2026-04-03 09:45:00'),
(5, 3, 'Python Database Connectivity', 'Connecting Python applications to MySQL databases.', 1, '2026-04-03 10:00:00'),
(6, 3, 'CRUD Operations with Python', 'Create, read, update, and delete data using Python.', 2, '2026-04-03 10:15:00'),
(7, 4, 'HTML and CSS Foundations', 'Building structured and styled web pages.', 1, '2026-04-03 10:30:00'),
(8, 4, 'Flask Routing Basics', 'Creating routes and rendering templates in Flask.', 2, '2026-04-03 10:45:00'),
(9, 5, 'Dashboard Design Principles', 'How to organize charts and indicators effectively.', 1, '2026-04-03 11:00:00'),
(10, 5, 'Building Interactive Reports', 'Presenting data insights using simple reporting tools.', 2, '2026-04-03 11:15:00');

INSERT INTO enrollments
(enrollment_id, learner_id, course_id, enrollment_date, status)
VALUES
(1, 1, 1, '2026-04-05', 'completed'),
(2, 1, 3, '2026-04-05', 'completed'),
(3, 2, 2, '2026-04-06', 'completed'),
(4, 2, 4, '2026-04-06', 'enrolled'),
(5, 3, 5, '2026-04-07', 'completed'),
(6, 3, 1, '2026-04-07', 'enrolled'),
(7, 4, 4, '2026-04-08', 'completed'),
(8, 5, 2, '2026-04-08', 'enrolled'),
(9, 5, 5, '2026-04-08', 'enrolled'),
(10, 4, 3, '2026-04-09', 'enrolled');

INSERT INTO courseassessments
(assessment_id, course_id, title, total_score, passing_score, created_at)
VALUES
(1, 1, 'Final Quiz: Introduction to SQL', 100, 70, '2026-04-10 08:00:00'),
(2, 2, 'Final Quiz: Database Design Fundamentals', 100, 70, '2026-04-10 08:10:00'),
(3, 3, 'Final Quiz: Python for Data Management', 100, 70, '2026-04-10 08:20:00'),
(4, 4, 'Final Quiz: Web Development Basics', 100, 70, '2026-04-10 08:30:00'),
(5, 5, 'Final Quiz: Data Visualization with BI Tools', 100, 70, '2026-04-10 08:40:00');

INSERT INTO learnerlectureprogress
(progress_id, learner_id, lecture_id, is_completed, completed_at)
VALUES
(1, 1, 1, 1, '2026-04-11 09:00:00'),
(2, 1, 2, 1, '2026-04-11 09:20:00'),
(3, 1, 5, 1, '2026-04-11 10:00:00'),
(4, 1, 6, 1, '2026-04-11 10:25:00'),
(5, 2, 3, 1, '2026-04-12 09:00:00'),
(6, 2, 4, 1, '2026-04-12 09:30:00'),
(7, 3, 9, 1, '2026-04-12 10:00:00'),
(8, 3, 10, 1, '2026-04-12 10:35:00'),
(9, 4, 7, 1, '2026-04-13 09:00:00'),
(10, 4, 8, 1, '2026-04-13 09:25:00');

INSERT INTO assessmentattempts
(attempt_id, assessment_id, learner_id, score, attempt_date, is_passed)
VALUES
(1, 1, 1, 85.00, '2026-04-14 08:30:00', 1),
(2, 3, 1, 92.00, '2026-04-14 09:00:00', 1),
(3, 2, 2, 78.00, '2026-04-14 09:30:00', 1),
(4, 5, 3, 88.00, '2026-04-14 10:00:00', 1),
(5, 4, 4, 74.00, '2026-04-14 10:30:00', 1),
(6, 1, 3, 60.00, '2026-04-14 11:00:00', 0),
(7, 2, 5, 65.00, '2026-04-14 11:30:00', 0),
(8, 5, 5, 68.00, '2026-04-14 12:00:00', 0);

INSERT INTO certificates
(certificate_id, learner_id, course_id, issue_date, certificate_code)
VALUES
(1, 1, 1, '2026-04-15 09:00:00', 'CERT-SQL-ALICE-001'),
(2, 1, 3, '2026-04-15 09:10:00', 'CERT-PY-ALICE-002'),
(3, 2, 2, '2026-04-15 09:20:00', 'CERT-DB-BINH-003'),
(4, 3, 5, '2026-04-15 09:30:00', 'CERT-BI-CHLOE-004'),
(5, 4, 4, '2026-04-15 09:40:00', 'CERT-WEB-DAVID-005');

INSERT INTO useraccounts
(account_id, username, password_hash, role, learner_id, instructor_id, is_active, created_at)
VALUES
(1, 'admin01', 'pbkdf2_demo_admin_001', 'admin', NULL, NULL, 1, '2026-04-16 08:00:00'),
(2, 'alice.learn', 'pbkdf2_demo_learner_001', 'learner', 1, NULL, 1, '2026-04-16 08:10:00'),
(3, 'binh.learn', 'pbkdf2_demo_learner_002', 'learner', 2, NULL, 1, '2026-04-16 08:20:00'),
(4, 'chloe.learn', 'pbkdf2_demo_learner_003', 'learner', 3, NULL, 1, '2026-04-16 08:30:00'),
(5, 'anna.instructor', 'pbkdf2_demo_instructor_001', 'instructor', NULL, 1, 1, '2026-04-16 08:40:00'),
(6, 'brian.instructor', 'pbkdf2_demo_instructor_002', 'instructor', NULL, 2, 1, '2026-04-16 08:50:00'),
(7, 'daniel.instructor', 'pbkdf2_demo_instructor_003', 'instructor', NULL, 4, 1, '2026-04-16 09:00:00');

INSERT INTO auditlogs
(log_id, action_type, table_name, reference_id, action_time, description)
VALUES
(1, 'INSERT', 'enrollments', 1, '2026-04-05 10:00:00', 'Learner Alice Nguyen enrolled in Introduction to SQL.'),
(2, 'INSERT', 'enrollments', 3, '2026-04-06 10:10:00', 'Learner Binh Tran enrolled in Database Design Fundamentals.'),
(3, 'UPDATE', 'learnerlectureprogress', 2, '2026-04-11 09:20:00', 'Alice Nguyen completed lecture 2 of Introduction to SQL.'),
(4, 'INSERT', 'assessmentattempts', 1, '2026-04-14 08:30:00', 'Alice Nguyen passed the final assessment for Introduction to SQL.'),
(5, 'INSERT', 'certificates', 1, '2026-04-15 09:00:00', 'Certificate issued to Alice Nguyen for Introduction to SQL.'),
(6, 'INSERT', 'certificates', 5, '2026-04-15 09:40:00', 'Certificate issued to David Le for Web Development Basics.');