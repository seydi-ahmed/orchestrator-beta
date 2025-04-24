import os


class Config:
    SQLALCHEMY_DATABASE_URI = (
        "postgresql://{user}:{password}@inventory-database:5432/{dbname}".format(
            user=os.environ.get("DB_USER"),
            password=os.environ.get("DB_PASSWORD"),
            dbname=os.environ.get("POSTGRES_DB"),
        )
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    DEBUG = True
