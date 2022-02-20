from flask import Flask, jsonify

app = Flask(__name__)


@app.route("/")
def home():
    return jsonify({"response": "OK", "code": 200})


@app.route('/seed', methods=['GET'])
def db_create():
    import psycopg2
    import os

    # get env vars
    DB_CXN_STR = os.getenv('DB_CONNECTION_STRING')
    print("DB Connection String: ", DB_CXN_STR)

    conn = psycopg2.connect(DB_CXN_STR)
    print("Connection established")

    cursor = conn.cursor()

    # Drop previous table of same name if one exists
    cursor.execute("DROP TABLE IF EXISTS inventory;")
    print("Finished dropping table (if existed)")

    # Create a table
    cursor.execute(
        "CREATE TABLE inventory (id serial PRIMARY KEY, name VARCHAR(50), quantity INTEGER);")
    print("Finished creating table")

    # Insert some data into the table
    cursor.execute(
        "INSERT INTO inventory (name, quantity) VALUES (%s, %s);", ("apple", 120))
    cursor.execute(
        "INSERT INTO inventory (name, quantity) VALUES (%s, %s);", ("banana", 340))
    cursor.execute(
        "INSERT INTO inventory (name, quantity) VALUES (%s, %s);", ("pear", 90))

    # Clean up
    conn.commit()
    cursor.close()
    conn.close()

    return 'complete'


@app.route('/inventory', methods=['GET'])
def db_read():
    import psycopg2
    import os

    # get env vars
    DB_CXN_STR = os.getenv('DB_CONNECTION_STRING')

    conn = psycopg2.connect(DB_CXN_STR)
    print("Connection established")

    cursor = conn.cursor()
    cursor.execute("SELECT name, quantity FROM inventory")
    rows = cursor.fetchall()

    results = [
        {
            "name": str(row[0]),
            "quantity": str(row[1])
        } for row in rows]

    # Clean up
    conn.commit()
    cursor.close()
    conn.close()

    return jsonify(results)

if __name__ == '__main__':
    app.run(debug=True)
