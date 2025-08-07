import sqlite3
import os
import bcrypt

# Lokasi direktori dan file database
db_dir = "db"
db_file = os.path.join(db_dir, "app.db")

# Buat direktori jika belum ada, pastikan itu folder
if not os.path.exists(db_dir):
    os.makedirs(db_dir, mode=0o700, exist_ok=True)
elif not os.path.isdir(db_dir):
    raise Exception(f"{db_dir} exists and is not a directory!")

# Hash password 'admin' pakai bcrypt
password_plain = b'admin'
password_hashed = bcrypt.hashpw(password_plain, bcrypt.gensalt())

try:
    conn = sqlite3.connect(db_file)
    cur = conn.cursor()

    # Buat tabel users jika belum ada
    cur.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL
        )
    """)

    # Cek apakah user admin sudah ada
    cur.execute("SELECT COUNT(*) FROM users WHERE username = ?", ('admin',))
    if cur.fetchone()[0] == 0:
        cur.execute("INSERT INTO users (username, password) VALUES (?, ?)", ('admin', password_hashed.decode()))

    conn.commit()
except Exception as e:
    print("Error:", e)
finally:
    if conn:
        conn.close()
