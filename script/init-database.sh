#!/bin/bash
# This script initializes the database.

set -e

source ./script/util.sh

if [[ -z $1 ]]; then
    echo "SQL Init Scripts path is not set."
    echo "Usage: $BASH_SCRIPT <sql init scripts path>"
    exit 1
fi

SQL_SCRIPTS_PATH=$1
echo "SQL_SCRIPTS_PATH=$SQL_SCRIPTS_PATH"

create_schema

execute_sql_script "$SQL_SCRIPTS_PATH/bfcdatabase.sql"

execute_sql_script "$SQL_SCRIPTS_PATH/bfc_sources.sql"
