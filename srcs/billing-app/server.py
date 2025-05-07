from app.consume_queue import consume_and_store_order
from app.orders import Base

from sqlalchemy import create_engine

import os


BILLING_DB_USER = os.getenv("BILLING_DB_USER")
BILLING_DB_PASSWORD = os.getenv("BILLING_DB_PASSWORD")
BILLING_DB_NAME = os.getenv("BILLING_DB_NAME")
BILLING_DB_HOST = os.getenv("BILLING_DB_HOST", "billing-db")  # valeur par défaut

# DB_URI = (
#     "postgresql://"
#     f'{BILLING_DB_USER}:{BILLING_DB_PASSWORD}'
#     f'@billing-db:5432/{BILLING_DB_NAME}'
# )

DB_URI = (
    "postgresql://"
    f"{BILLING_DB_USER}:{BILLING_DB_PASSWORD}"
    f"@{BILLING_DB_HOST}:5432/{BILLING_DB_NAME}"
)

engine = create_engine(DB_URI)
Base.metadata.create_all(engine)

consume_and_store_order(engine)
