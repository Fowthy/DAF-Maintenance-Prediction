#!/bin/bash
# This script contains common bash functions.

set -e

function execute_sql_script {
    echo "Executing $1."
    docker exec -i daf-mysql mysql -u root daf < "$1"
}

function execute_sql {
    echo "Executing $1."
    docker exec -i daf-mysql mysql -u root -e "$1"
}

function create_schema {
    echo "Creating schema daf."
    execute_sql "CREATE SCHEMA IF NOT EXISTS daf;"
}
