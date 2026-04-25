from werkzeug.security import generate_password_hash
from db import execute_commit

demo_accounts = {
    "admin01": "Admin@123",
    "alice.learn": "Alice@123",
    "binh.learn": "Binh@123",
    "chloe.learn": "Chloe@123",
    "anna.instructor": "Anna@123",
    "brian.instructor": "Brian@123",
    "daniel.instructor": "Daniel@123"
}

for username, plain_password in demo_accounts.items():
    hashed_password = generate_password_hash(plain_password)
    execute_commit(
        "UPDATE useraccounts SET password_hash = %s WHERE username = %s",
        (hashed_password, username)
    )

print("Demo passwords updated successfully.")