# HaiAnhLearn

HaiAnhLearn is a database-driven online course management system developed for the **Introduction to Database System** final project.

The project combines **MySQL**, **Python Flask**, and a web interface to demonstrate how a well-designed relational database can support realistic academic workflows such as learner registration, course enrollment, lecture completion, assessment handling, certificate generation, and reporting.

## Features

### Core Database Features

- Learner management
- Instructor management
- Course management
- Lecture management
- Enrollment tracking
- Learner progress tracking
- Assessment attempts
- Certificate generation
- Audit logging

### Advanced Database Objects

- Indexes
- Views
- Stored procedures
- User-defined functions
- Triggers

### Security and Administration

- MySQL user privilege management
- Role-based access control
- Backup file creation
- Query optimization support

### Web Application Features

- Learner registration and login
- Role-based routing
- Learner dashboard
- Course catalog
- Lecture completion workflow
- Assessment submission
- Certificate display
- Instructor reporting
- Admin dashboard and reports

## Technologies Used

- MySQL
- MySQL Workbench
- Python
- Flask
- mysql-connector-python
- HTML
- CSS
- Jinja2

## Project Structure

```text
HaiAnhLearn/
├── docs/
│   ├── 04_database_diagram.png
│   └── screenshots/
├── sql/
│   ├── 01_create_database.sql
│   ├── 02_create_tables.sql
│   ├── 03_insert_sample_data.sql
│   ├── 05_indexes.sql
│   ├── 06_views.sql
│   ├── 07_procedures.sql
│   ├── 08_functions.sql
│   ├── 09_triggers.sql
│   └── 10_security_users.sql
├── static/
│   └── style.css
├── templates/
│   ├── add_course.html
│   ├── admin_dashboard.html
│   ├── admin_learners.html
│   ├── assessment.html
│   ├── base.html
│   ├── certificates.html
│   ├── course_catalog.html
│   ├── edit_learner.html
│   ├── enrollments.html
│   ├── index.html
│   ├── instructor_dashboard.html
│   ├── instructor_reports.html
│   ├── learner_course_detail.html
│   ├── learner_dashboard.html
│   ├── login.html
│   ├── register.html
│   └── reports.html
├── .env.example
├── .gitignore
├── app.py
├── db.py
├── haianhlearn_backup.sql
├── README.md
├── requirements.txt
└── seed_demo_passwords.py
```

## Database Setup

Open MySQL Workbench and execute the SQL scripts in the following order:

1. `sql/01_create_database.sql`
2. `sql/02_create_tables.sql`
3. `sql/03_insert_sample_data.sql`
4. `sql/05_indexes.sql`
5. `sql/06_views.sql`
6. `sql/07_procedures.sql`
7. `sql/08_functions.sql`
8. `sql/09_triggers.sql`
9. `sql/10_security_users.sql`

The database diagram is stored in:

```text
docs/04_database_diagram.png
```

## Environment Setup

Create a `.env` file based on `.env.example`.

Example:

```text
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=haianhlearn_db
SECRET_KEY=your_secret_key
```

The real `.env` file is not uploaded to GitHub for security reasons.

## Install Dependencies

Install the required Python packages:

```bash
pip install -r requirements.txt
```

## How to Run

Run the Flask application:

```bash
python app.py
```

Then open the application in a browser:

```text
http://127.0.0.1:5000
```

## Demo Accounts

### Admin
- Username: `admin01`
- Password: `Admin@123`

### Instructor
- Username: `anna.instructor`
- Password: `Anna@123`

## Demo Password Setup

The project includes a helper script for preparing demo passwords:

```bash
python seed_demo_passwords.py
```

This script can be used after the database and sample data have been created.

## Backup File

A database backup file is included:

```text
haianhlearn_backup.sql
```

This file can be restored in MySQL if needed.

## Submission Note

This GitHub repository contains the source code, SQL scripts, database diagram, screenshots, and supporting project files.

The final PDF report and other required deliverables are submitted separately through LMS according to the course requirements.
