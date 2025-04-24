import os


class Config:
    SQLALCHEMY_DATABASE_URI = (
        "postgresql://{user}:{password}@billing-database:5432/{dbname}".format(
            user=os.environ.get("DB_USER"),
            password=os.environ.get("DB_PASSWORD"),
            dbname=os.environ.get("POSTGRES_DB"),
        )
    )
    SECRET_KEY = os.getenv("SECRET_KEY")
    DEBUG = True
    RABBITMQ_HOST = os.getenv("RABBITMQ_HOST")
    RABBITMQ_USER = os.getenv("RABBITMQ_DEFAULT_USER")
    RABBITMQ_PASSWORD = os.getenv("RABBITMQ_DEFAULT_PASS")
    RABBITMQ_TASK_QUEUE = "billing_queue"
    RABBITMQ_RESPONSE_QUEUE = "response_queue"
