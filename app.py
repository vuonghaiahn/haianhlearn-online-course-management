import os
import mysql.connector
from functools import wraps

from flask import (
    Flask, render_template, request, redirect,
    url_for, session, flash
)
from dotenv import load_dotenv
from werkzeug.security import generate_password_hash, check_password_hash

from db import fetch_all, fetch_one, execute_commit

load_dotenv()

app = Flask(__name__)
app.secret_key = os.getenv("SECRET_KEY")


def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if "user_id" not in session:
            flash("Please log in first.", "warning")
            return redirect(url_for("login"))
        return f(*args, **kwargs)
    return decorated_function


def role_required(required_role):
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if "role" not in session:
                flash("Please log in first.", "warning")
                return redirect(url_for("login"))

            if session["role"] != required_role:
                flash("You do not have permission to access this page.", "danger")
                return redirect(url_for("dashboard"))
            return f(*args, **kwargs)
        return decorated_function
    return decorator


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        learner_name = request.form["learner_name"].strip()
        email = request.form["email"].strip()
        phone_number = request.form["phone_number"].strip()
        username = request.form["username"].strip()
        password = request.form["password"]
        confirm_password = request.form["confirm_password"]

        if password != confirm_password:
            flash("Passwords do not match.", "danger")
            return redirect(url_for("register"))

        password_hash = generate_password_hash(password)

        try:
            execute_commit(
                "CALL sp_register_learner_account(%s, %s, %s, %s, %s)",
                (learner_name, email, phone_number, username, password_hash)
            )
            flash("Registration successful. Please log in.", "success")
            return redirect(url_for("login"))
        except mysql.connector.Error as err:
            flash(getattr(err, "msg", str(err)), "danger")
            return redirect(url_for("register"))

    return render_template("register.html")


@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form["username"].strip()
        password = request.form["password"]

        user = fetch_one(
            """
            SELECT *
            FROM useraccounts
            WHERE username = %s AND is_active = 1
            """,
            (username,)
        )

        if not user:
            flash("Invalid username or password.", "danger")
            return redirect(url_for("login"))

        if not check_password_hash(user["password_hash"], password):
            flash("Invalid username or password.", "danger")
            return redirect(url_for("login"))

        session["user_id"] = user["account_id"]
        session["username"] = user["username"]
        session["role"] = user["role"]
        session["learner_id"] = user["learner_id"]
        session["instructor_id"] = user["instructor_id"]

        flash("Login successful.", "success")
        return redirect(url_for("dashboard"))

    return render_template("login.html")


@app.route("/logout")
def logout():
    session.clear()
    flash("You have logged out.", "info")
    return redirect(url_for("index"))


@app.route("/dashboard")
@login_required
def dashboard():
    role = session.get("role")

    if role == "learner":
        return redirect(url_for("learner_dashboard"))
    elif role == "instructor":
        return redirect(url_for("instructor_dashboard"))
    elif role == "admin":
        return redirect(url_for("admin_dashboard"))

    flash("Unknown role.", "danger")
    return redirect(url_for("login"))


# =========================
# LEARNER
# =========================
@app.route("/learner/dashboard")
@login_required
@role_required("learner")
def learner_dashboard():
    learner_id = session.get("learner_id")

    progress_rows = fetch_all(
        """
        SELECT *
        FROM vw_learner_course_progress
        WHERE learner_id = %s
        ORDER BY course_name
        """,
        (learner_id,)
    )

    return render_template("learner_dashboard.html", progress_rows=progress_rows)


@app.route("/learner/courses")
@login_required
@role_required("learner")
def learner_courses():
    learner_id = session.get("learner_id")

    courses = fetch_all(
        """
        SELECT
            c.course_id,
            c.course_name,
            c.description,
            i.instructor_name,
            CASE
                WHEN e.enrollment_id IS NULL THEN 0
                ELSE 1
            END AS is_enrolled
        FROM courses c
        JOIN instructors i
            ON c.instructor_id = i.instructor_id
        LEFT JOIN enrollments e
            ON c.course_id = e.course_id
           AND e.learner_id = %s
        ORDER BY c.course_name
        """,
        (learner_id,)
    )

    return render_template("course_catalog.html", courses=courses)


@app.route("/learner/enroll/<int:course_id>", methods=["POST"])
@login_required
@role_required("learner")
def learner_enroll(course_id):
    learner_id = session.get("learner_id")

    try:
        execute_commit(
            "CALL sp_enroll_learner_in_course(%s, %s)",
            (learner_id, course_id)
        )
        flash("Course enrollment successful.", "success")
    except mysql.connector.Error as err:
        flash(getattr(err, "msg", str(err)), "danger")

    return redirect(url_for("learner_courses"))

@app.route("/learner/course/<int:course_id>")
@login_required
@role_required("learner")
def learner_course_detail(course_id):
    learner_id = session.get("learner_id")

    enrolled = fetch_one(
        """
        SELECT e.enrollment_id, c.course_id, c.course_name, c.description
        FROM enrollments e
        JOIN courses c ON e.course_id = c.course_id
        WHERE e.learner_id = %s AND e.course_id = %s
        """,
        (learner_id, course_id)
    )

    if not enrolled:
        flash("You are not enrolled in this course.", "danger")
        return redirect(url_for("learner_courses"))

    lectures = fetch_all(
        """
        SELECT
            lec.lecture_id,
            lec.title,
            lec.content,
            lec.lecture_order,
            COALESCE(llp.is_completed, 0) AS is_completed,
            llp.completed_at
        FROM lectures lec
        LEFT JOIN learnerlectureprogress llp
            ON lec.lecture_id = llp.lecture_id
           AND llp.learner_id = %s
        WHERE lec.course_id = %s
        ORDER BY lec.lecture_order
        """,
        (learner_id, course_id)
    )

    progress_summary = fetch_one(
        """
        SELECT
            fn_total_completed_lectures(%s, %s) AS completed_lectures,
            (SELECT COUNT(*) FROM lectures WHERE course_id = %s) AS total_lectures,
            fn_completion_percentage(%s, %s) AS completion_percentage
        """,
        (learner_id, course_id, course_id, learner_id, course_id)
    )

    assessment = fetch_one(
        """
        SELECT assessment_id, title, total_score, passing_score
        FROM courseassessments
        WHERE course_id = %s
        """,
        (course_id,)
    )

    certificate = fetch_one(
        """
        SELECT certificate_id, certificate_code, issue_date
        FROM certificates
        WHERE learner_id = %s AND course_id = %s
        """,
        (learner_id, course_id)
    )

    return render_template(
        "learner_course_detail.html",
        course=enrolled,
        lectures=lectures,
        progress_summary=progress_summary,
        assessment=assessment,
        certificate=certificate
    )


@app.route("/learner/lecture/<int:lecture_id>/complete", methods=["POST"])
@login_required
@role_required("learner")
def complete_lecture(lecture_id):
    learner_id = session.get("learner_id")

    lecture = fetch_one(
        """
        SELECT lec.lecture_id, lec.course_id, lec.title
        FROM lectures lec
        JOIN enrollments e
            ON lec.course_id = e.course_id
        WHERE lec.lecture_id = %s
          AND e.learner_id = %s
        """,
        (lecture_id, learner_id)
    )

    if not lecture:
        flash("Lecture not found or you are not enrolled in its course.", "danger")
        return redirect(url_for("learner_courses"))

    existing_progress = fetch_one(
        """
        SELECT progress_id, is_completed
        FROM learnerlectureprogress
        WHERE learner_id = %s AND lecture_id = %s
        """,
        (learner_id, lecture_id)
    )

    if existing_progress:
        if existing_progress["is_completed"] == 1:
            flash("This lecture is already completed.", "info")
        else:
            execute_commit(
                """
                UPDATE learnerlectureprogress
                SET is_completed = 1,
                    completed_at = NOW()
                WHERE learner_id = %s AND lecture_id = %s
                """,
                (learner_id, lecture_id)
            )
            flash("Lecture marked as completed.", "success")
    else:
        execute_commit(
            """
            INSERT INTO learnerlectureprogress
            (learner_id, lecture_id, is_completed, completed_at)
            VALUES (%s, %s, 1, NOW())
            """,
            (learner_id, lecture_id)
        )
        flash("Lecture marked as completed.", "success")

    return redirect(url_for("learner_course_detail", course_id=lecture["course_id"]))

@app.route("/learner/course/<int:course_id>/assessment", methods=["GET", "POST"])
@login_required
@role_required("learner")
def learner_assessment(course_id):
    learner_id = session.get("learner_id")

    enrolled = fetch_one(
        """
        SELECT e.enrollment_id, c.course_id, c.course_name
        FROM enrollments e
        JOIN courses c ON e.course_id = c.course_id
        WHERE e.learner_id = %s AND e.course_id = %s
        """,
        (learner_id, course_id)
    )

    if not enrolled:
        flash("You are not enrolled in this course.", "danger")
        return redirect(url_for("learner_courses"))

    assessment = fetch_one(
        """
        SELECT assessment_id, title, total_score, passing_score
        FROM courseassessments
        WHERE course_id = %s
        """,
        (course_id,)
    )

    if not assessment:
        flash("No assessment found for this course.", "warning")
        return redirect(url_for("learner_course_detail", course_id=course_id))

    if request.method == "POST":
        try:
            score = float(request.form["score"])
        except ValueError:
            flash("Please enter a valid score.", "danger")
            return redirect(url_for("learner_assessment", course_id=course_id))

        if score < 0 or score > assessment["total_score"]:
            flash(f"Score must be between 0 and {assessment['total_score']}.", "danger")
            return redirect(url_for("learner_assessment", course_id=course_id))

        execute_commit(
            """
            INSERT INTO assessmentattempts (assessment_id, learner_id, score, attempt_date)
            VALUES (%s, %s, %s, NOW())
            """,
            (assessment["assessment_id"], learner_id, score)
        )

        flash("Assessment submitted successfully.", "success")
        return redirect(url_for("learner_assessment", course_id=course_id))

    attempts = fetch_all(
        """
        SELECT attempt_id, score, is_passed, attempt_date
        FROM assessmentattempts
        WHERE learner_id = %s AND assessment_id = %s
        ORDER BY attempt_date DESC
        """,
        (learner_id, assessment["assessment_id"])
    )

    certificate = fetch_one(
        """
        SELECT certificate_id, certificate_code, issue_date
        FROM certificates
        WHERE learner_id = %s AND course_id = %s
        """,
        (learner_id, course_id)
    )

    return render_template(
        "assessment.html",
        course=enrolled,
        assessment=assessment,
        attempts=attempts,
        certificate=certificate
    )
    
@app.route("/learner/certificates")
@login_required
@role_required("learner")
def learner_certificates():
    learner_id = session.get("learner_id")

    certificates = fetch_all(
        """
        SELECT
            cert.certificate_id,
            cert.certificate_code,
            cert.issue_date,
            c.course_name
        FROM certificates cert
        JOIN courses c
            ON cert.course_id = c.course_id
        WHERE cert.learner_id = %s
        ORDER BY cert.issue_date DESC
        """,
        (learner_id,)
    )

    return render_template("certificates.html", certificates=certificates)

# =========================
# INSTRUCTOR
# =========================
@app.route("/instructor/dashboard")
@login_required
@role_required("instructor")
def instructor_dashboard():
    instructor_id = session.get("instructor_id")

    teaching_load = fetch_all(
        """
        SELECT *
        FROM vw_instructor_teaching_load
        WHERE instructor_id = %s
        ORDER BY course_name
        """,
        (instructor_id,)
    )

    return render_template("instructor_dashboard.html", teaching_load=teaching_load)

@app.route("/instructor/reports")
@login_required
@role_required("instructor")
def instructor_reports():
    instructor_id = session.get("instructor_id")

    rows = fetch_all(
        """
        SELECT *
        FROM vw_instructor_student_progress
        WHERE instructor_id = %s
        ORDER BY course_name, learner_name
        """,
        (instructor_id,)
    )

    return render_template("instructor_reports.html", rows=rows)

# =========================
# ADMIN
# =========================
@app.route("/admin/dashboard")
@login_required
@role_required("admin")
def admin_dashboard():
    summary = fetch_one("SELECT * FROM vw_admin_dashboard_summary")

    return render_template("admin_dashboard.html", summary=summary)


@app.route("/admin/learners", methods=["GET", "POST"])
@login_required
@role_required("admin")
def admin_learners():
    if request.method == "POST":
        learner_name = request.form["learner_name"].strip()
        email = request.form["email"].strip()
        phone_number = request.form["phone_number"].strip()

        existing = fetch_one(
            "SELECT * FROM learners WHERE email = %s",
            (email,)
        )

        if existing:
            flash("Learner email already exists.", "danger")
            return redirect(url_for("admin_learners"))

        execute_commit(
            """
            INSERT INTO learners (learner_name, email, phone_number)
            VALUES (%s, %s, %s)
            """,
            (learner_name, email, phone_number)
        )

        flash("Learner added successfully.", "success")
        return redirect(url_for("admin_learners"))

    learners = fetch_all(
        "SELECT * FROM learners ORDER BY learner_id DESC"
    )

    return render_template("admin_learners.html", learners=learners)


@app.route("/admin/learners/edit/<int:learner_id>", methods=["GET", "POST"])
@login_required
@role_required("admin")
def edit_learner(learner_id):
    learner = fetch_one(
        "SELECT * FROM learners WHERE learner_id = %s",
        (learner_id,)
    )

    if not learner:
        flash("Learner not found.", "danger")
        return redirect(url_for("admin_learners"))

    if request.method == "POST":
        learner_name = request.form["learner_name"].strip()
        email = request.form["email"].strip()
        phone_number = request.form["phone_number"].strip()

        existing = fetch_one(
            """
            SELECT * FROM learners
            WHERE email = %s AND learner_id <> %s
            """,
            (email, learner_id)
        )

        if existing:
            flash("Another learner is already using this email.", "danger")
            return redirect(url_for("edit_learner", learner_id=learner_id))

        execute_commit(
            """
            UPDATE learners
            SET learner_name = %s,
                email = %s,
                phone_number = %s
            WHERE learner_id = %s
            """,
            (learner_name, email, phone_number, learner_id)
        )

        flash("Learner updated successfully.", "success")
        return redirect(url_for("admin_learners"))

    return render_template("edit_learner.html", learner=learner)


@app.route("/admin/courses/add", methods=["GET", "POST"])
@login_required
@role_required("admin")
def add_course():
    instructors = fetch_all(
        "SELECT * FROM instructors ORDER BY instructor_name"
    )

    if request.method == "POST":
        course_name = request.form["course_name"].strip()
        description = request.form["description"].strip()
        instructor_id = request.form["instructor_id"]

        execute_commit(
            """
            INSERT INTO courses (course_name, description, instructor_id)
            VALUES (%s, %s, %s)
            """,
            (course_name, description, instructor_id)
        )

        flash("Course added successfully.", "success")
        return redirect(url_for("add_course"))

    return render_template("add_course.html", instructors=instructors)


@app.route("/admin/enrollments")
@login_required
@role_required("admin")
def admin_enrollments():
    rows = fetch_all(
        """
        SELECT
            e.enrollment_id,
            l.learner_name,
            c.course_name,
            e.enrollment_date,
            e.status
        FROM enrollments e
        JOIN learners l
            ON e.learner_id = l.learner_id
        JOIN courses c
            ON e.course_id = c.course_id
        ORDER BY e.enrollment_date DESC, e.enrollment_id DESC
        """
    )

    return render_template("enrollments.html", rows=rows)


@app.route("/admin/reports")
@login_required
@role_required("admin")
def admin_reports():
    summary = fetch_one("SELECT * FROM vw_admin_dashboard_summary")

    active_courses = fetch_all(
        """
        SELECT
            c.course_id,
            c.course_name,
            COUNT(e.enrollment_id) AS total_enrollments
        FROM courses c
        LEFT JOIN enrollments e
            ON c.course_id = e.course_id
        GROUP BY c.course_id, c.course_name
        HAVING COUNT(e.enrollment_id) > 0
        ORDER BY total_enrollments DESC, c.course_name
        """
    )

    teaching_load = fetch_all(
        """
        SELECT
            instructor_name,
            course_name,
            total_enrolled_learners,
            total_completed_learners
        FROM vw_instructor_teaching_load
        ORDER BY instructor_name, course_name
        """
    )

    return render_template(
        "reports.html",
        summary=summary,
        active_courses=active_courses,
        teaching_load=teaching_load
    )


if __name__ == "__main__":
    app.run(debug=True)