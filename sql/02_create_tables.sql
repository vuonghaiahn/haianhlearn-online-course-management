USE haianhlearn_db;

CREATE TABLE learners (
    learner_id INT AUTO_INCREMENT PRIMARY KEY,
    learner_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone_number VARCHAR(20),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE instructors (
    instructor_id INT AUTO_INCREMENT PRIMARY KEY,
    instructor_name VARCHAR(100) NOT NULL,
    expertise VARCHAR(100),
    email VARCHAR(100) NOT NULL UNIQUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE courses (
    course_id INT AUTO_INCREMENT PRIMARY KEY,
    course_name VARCHAR(150) NOT NULL,
    description TEXT,
    instructor_id INT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_courses_instructor
        FOREIGN KEY (instructor_id)
        REFERENCES instructors(instructor_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE lectures (
    lecture_id INT AUTO_INCREMENT PRIMARY KEY,
    course_id INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    content TEXT,
    lecture_order INT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_lectures_course
        FOREIGN KEY (course_id)
        REFERENCES courses(course_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT uq_lectures_course_order
        UNIQUE (course_id, lecture_order)
) ENGINE=InnoDB;

CREATE TABLE enrollments (
    enrollment_id INT AUTO_INCREMENT PRIMARY KEY,
    learner_id INT NOT NULL,
    course_id INT NOT NULL,
    enrollment_date DATE NOT NULL,
    status ENUM('enrolled', 'completed', 'cancelled') NOT NULL DEFAULT 'enrolled',
    CONSTRAINT fk_enrollments_learner
        FOREIGN KEY (learner_id)
        REFERENCES learners(learner_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_enrollments_course
        FOREIGN KEY (course_id)
        REFERENCES courses(course_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT uq_enrollments_learner_course
        UNIQUE (learner_id, course_id)
) ENGINE=InnoDB;

CREATE TABLE useraccounts (
    account_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin', 'instructor', 'learner') NOT NULL,
    learner_id INT NULL UNIQUE,
    instructor_id INT NULL UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_useraccounts_learner
        FOREIGN KEY (learner_id)
        REFERENCES learners(learner_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    CONSTRAINT fk_useraccounts_instructor
        FOREIGN KEY (instructor_id)
        REFERENCES instructors(instructor_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE learnerlectureprogress (
    progress_id INT AUTO_INCREMENT PRIMARY KEY,
    learner_id INT NOT NULL,
    lecture_id INT NOT NULL,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at DATETIME NULL,
    CONSTRAINT fk_progress_learner
        FOREIGN KEY (learner_id)
        REFERENCES learners(learner_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_progress_lecture
        FOREIGN KEY (lecture_id)
        REFERENCES lectures(lecture_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT uq_progress_learner_lecture
        UNIQUE (learner_id, lecture_id)
) ENGINE=InnoDB;

CREATE TABLE courseassessments (
    assessment_id INT AUTO_INCREMENT PRIMARY KEY,
    course_id INT NOT NULL UNIQUE,
    title VARCHAR(150) NOT NULL,
    total_score INT NOT NULL DEFAULT 100,
    passing_score INT NOT NULL DEFAULT 70,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_courseassessments_score
        CHECK (
            total_score > 0 AND
            passing_score >= 0 AND
            passing_score <= total_score
        ),
    CONSTRAINT fk_courseassessments_course
        FOREIGN KEY (course_id)
        REFERENCES courses(course_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE assessmentattempts (
    attempt_id INT AUTO_INCREMENT PRIMARY KEY,
    assessment_id INT NOT NULL,
    learner_id INT NOT NULL,
    score DECIMAL(5,2) NOT NULL,
    attempt_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_passed BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT chk_assessmentattempts_score
        CHECK (score >= 0 AND score <= 100),
    CONSTRAINT fk_assessmentattempts_assessment
        FOREIGN KEY (assessment_id)
        REFERENCES courseassessments(assessment_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_assessmentattempts_learner
        FOREIGN KEY (learner_id)
        REFERENCES learners(learner_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE certificates (
    certificate_id INT AUTO_INCREMENT PRIMARY KEY,
    learner_id INT NOT NULL,
    course_id INT NOT NULL,
    issue_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    certificate_code VARCHAR(50) NOT NULL UNIQUE,
    CONSTRAINT fk_certificates_learner
        FOREIGN KEY (learner_id)
        REFERENCES learners(learner_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_certificates_course
        FOREIGN KEY (course_id)
        REFERENCES courses(course_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT uq_certificates_learner_course
        UNIQUE (learner_id, course_id)
) ENGINE=InnoDB;

CREATE TABLE auditlogs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    action_type VARCHAR(50) NOT NULL,
    table_name VARCHAR(50) NOT NULL,
    reference_id INT NOT NULL,
    action_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    description TEXT
) ENGINE=InnoDB;