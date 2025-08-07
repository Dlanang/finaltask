
import sqlite3, os
os.makedirs("db", exist_ok=True)
conn = sqlite3.connect("db/app.db")
cur = conn.cursor()
cur.execute("CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, username TEXT, password TEXT)")
cur.execute("INSERT INTO users (username, password) VALUES ('admin', 'admin')")
conn.commit()
conn.close()
