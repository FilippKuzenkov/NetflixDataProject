import sqlalchemy as sal
import pandas as pd

# Load your DataFrame
df = pd.read_csv('netflix_titles.csv', encoding='utf-8')

# Define the connection string
connection_string = 'mssql://LenovoThinkBook\\SQLEXPRESS/master?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes'

# Create the SQLAlchemy engine
engine = sal.create_engine(connection_string)

try:
    # Establish the connection
    with engine.connect() as conn:
        print("Connection successful!")
        
        # Insert the DataFrame into the SQL Server table
        df.to_sql('netflix_raw', con=conn, index=False, if_exists='append')
        print("Data inserted successfully!")

except Exception as e:
    print(f"An error occurred: {e}")


#Checking why do we see ??? symbols in our data
df.head()
df[df.show_id=='s5023']

#Looking at the maximum lengths to then correctly create the new table
max(df.show_id.str.len())
max(df.type.str.len())
max(df.title.str.len())
max(df.director.str.len())
max(df.cast.dropna().str.len())
max(df.country.str.len())

max(df.date_added.dropna().str.len())

max(df.release_year.dropna().astype(str).str.len())
max(df.rating.str.len())
max(df.duration.str.len())
max(df.listed_in.str.len())
max(df.description.str.len())

df.isna().sum() #checking sum if null values for each column
