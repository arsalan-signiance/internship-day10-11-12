import mysql.connector
import os
import time

class DBHelper:
    def __init__(self):
        self.host = os.getenv('DB_HOST')
        self.user = os.getenv('DB_USER')
        self.password = os.getenv('DB_PASSWORD')
        self.database = os.getenv('DB_NAME')
        self.port = 3306

    def get_connection(self):
        retries = 5
        while retries > 0:
            try:
                connection = mysql.connector.connect(
                    host=self.host,
                    user=self.user,
                    password=self.password,
                    database=self.database,
                    port=self.port
                )
                return connection
            except mysql.connector.Error as err:
                print(f"Error connecting to DB: {err}")
                retries -= 1
                time.sleep(2)
        raise Exception("Could not connect to database after retries")

    def execute_query(self, query, params=None):
        conn = self.get_connection()
        cursor = conn.cursor(dictionary=True)
        try:
            cursor.execute(query, params or ())
            conn.commit()
            return cursor
        except mysql.connector.Error as err:
            print(f"Error executing query: {err}")
            conn.rollback()
            raise
        finally:
            cursor.close()
            conn.close()

    def fetch_all(self, query, params=None):
        conn = self.get_connection()
        cursor = conn.cursor(dictionary=True)
        try:
            cursor.execute(query, params or ())
            return cursor.fetchall()
        except mysql.connector.Error as err:
            print(f"Error executing query: {err}")
            raise
        finally:
            cursor.close()
            conn.close()

    def fetch_one(self, query, params=None):
        conn = self.get_connection()
        cursor = conn.cursor(dictionary=True)
        try:
            cursor.execute(query, params or ())
            return cursor.fetchone()
        except mysql.connector.Error as err:
            print(f"Error executing query: {err}")
            raise
        finally:
            cursor.close()
            conn.close()
