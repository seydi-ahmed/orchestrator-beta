#!/bin/bash

#!/bin/bash

# Vérifie si le répertoire PostgreSQL existe, sinon l'initialise
if [ ! -d "/var/lib/postgresql/13/main/" ]; then
    mkdir -p /var/lib/postgresql/13/main
    /usr/lib/postgresql/13/bin/initdb -D /var/lib/postgresql/13/main/
fi

# Démarre PostgreSQL
/etc/init.d/postgresql start

# Configure la base de données en fonction des variables disponibles
if [ -n "$BILLING_DB_USER" ]; then
    echo "Configuring Billing DB..."
    psql --command "ALTER USER postgres WITH PASSWORD '${BILLING_DB_PASSWORD}';"
    psql --command "CREATE USER ${BILLING_DB_USER} WITH SUPERUSER PASSWORD '${BILLING_DB_PASSWORD}';"
    createdb -O ${BILLING_DB_USER} ${BILLING_DB_NAME}
elif [ -n "$INVENTORY_DB_USER" ]; then
    echo "Configuring Inventory DB..."
    psql --command "ALTER USER postgres WITH PASSWORD '${INVENTORY_DB_PASSWORD}';"
    psql --command "CREATE USER ${INVENTORY_DB_USER} WITH SUPERUSER PASSWORD '${INVENTORY_DB_PASSWORD}';"
    createdb -O ${INVENTORY_DB_USER} ${INVENTORY_DB_NAME}
else
    echo "Error: No DB configuration found (BILLING_DB_* or INVENTORY_DB_* variables missing)."
    exit 1
fi

# Autorise les connexions distantes
echo "listen_addresses='*'" >> /var/lib/postgresql/13/main/postgresql.conf
echo "host all all 0.0.0.0/0 md5" >> /var/lib/postgresql/13/main/pg_hba.conf

# Redémarre PostgreSQL pour appliquer les changements
/etc/init.d/postgresql stop
exec /usr/lib/postgresql/13/bin/postgres -D /var/lib/postgresql/13/main

# # ./srcs/postgres-db/tools/setup_db.sh

# #check if database already configured
# if [ ! -d "/var/lib/postgresql/13/main/" ]; then

#     mkdir -p /var/lib/postgresql/13/main

#     # Init the database
#     /usr/lib/postgresql/13/bin/initdb -D /var/lib/postgresql/13/main/

#     #Start postgresql
#     /etc/init.d/postgresql start

#     # Enable the PostgreSQL public access
#     psql --command "ALTER USER postgres WITH PASSWORD '${DB_PASSWORD}';"

#     # Create a new user and database
#     psql --command "CREATE USER ${DB_USER} WITH SUPERUSER PASSWORD '${DB_PASSWORD}';" &&\
#     createdb -O ${DB_USER} ${DB_NAME}

#     # Enable public access
#     echo "listen_addresses='*'" >> /var/lib/postgresql/13/main/postgresql.conf

#     # Enable public access
#     echo "host  all  all 0.0.0.0/0 md5" >> /var/lib/postgresql/13/main/pg_hba.conf
# fi

# /etc/init.d/postgresql stop

# # Start PostgreSQL
# /usr/lib/postgresql/13/bin/postgres -D /var/lib/postgresql/13/main
