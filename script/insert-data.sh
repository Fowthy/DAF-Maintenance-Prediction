#!/bin/bash
# This script inserts data into the database.

set -e

source ./script/util.sh

if [[ -z $1 ]]; then
    echo "SQL Data Scripts path is not set."
    echo "Usage: $BASH_SCRIPT '<sql data scripts path>'"
    exit 1
fi

SQL_SCRIPTS_PATH=$1
echo "SQL_SCRIPTS_PATH=$SQL_SCRIPTS_PATH"

cd "$SQL_SCRIPTS_PATH"

for FILE in *;
do 
    execute_sql_script "$FILE"
done
