import pymysql

def get_db_connection():
    """Returns a database connection."""
    return pymysql.connect(
        host='localhost',
        user='root',
        password='priya123',
        database='online_food_order_system'
    )

def execute_query(query, params=None):
    """Executes a query and returns the result."""
    connection = get_db_connection()
    with connection.cursor() as cursor:
        cursor.execute(query, params)
        result = cursor.fetchone()  # Fetch a single record
    connection.close()
    return result
