import psycopg2

conn = psycopg2.connect('host=whitewalker.cgdtqi20ig9l.us-east-2.rds.amazonaws.com                             port=5432                             dbname=aledade                             user=jameswalker                             password=jamesoliver69')
cursor = conn.cursor()

cursor.execute('select * from import.physician_compare limit 10')
results = cursor.fetchall()


