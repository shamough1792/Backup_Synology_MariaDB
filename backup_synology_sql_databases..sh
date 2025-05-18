#!/bin/bash
# backup_sql_databases.sh
#
# Script dumps all MySQL (or MariaDB) databases to separate SQL files (compressed to .sql.gz) 
# with more readable filenames. It also removes old backups (older than specified amount of days).

############
# Settings #
############

# WARNING: THIS SCRIPT WILL DELETE ANY FILES OLDER THAN DAYS_KEEP IN BACKUP_DIR!
# Make sure BACKUP_DIR is correctly set and contains only the intended backup files.

BACKUP_DIR=/path_to_store_backup/
DAYS_KEEP=5 # script will remove backups older than $DAYS_KEEP days
SQL_USER=root
SQL_PASS=Your_db_Password
MYSQL_DIR="/volume1/@appstore/MariaDB10/usr/local/mariadb10/bin/"

#############
# Main part #
#############
DATE=$(date +%Y-%m-%d)               # Format: 2023-05-19
TIME=$(date +%H%M)                   # Format: 1430 (for 2:30 PM)
DATESTAMP="${DATE}_${TIME}"           # Combines to: 2023-05-19_1430

# Create backup directory with today's date if it doesn't exist
TODAYS_BACKUP_DIR="${BACKUP_DIR}${DATE}/"
mkdir -p "$TODAYS_BACKUP_DIR"

# remove backups older than $DAYS_KEEP
find "${BACKUP_DIR}" -type d -mtime +$DAYS_KEEP -exec rm -rf {} \; 2> /dev/null

# list MySQL databases and dump each
databases=$("$MYSQL_DIR/mysql" --user="$SQL_USER" --password="$SQL_PASS" -e "SHOW DATABASES;" | tr -d "| " | grep -v Database)

for db in $databases; do
    # Skip system databases
    if [[ "$db" != _* ]] && [[ "$db" != "mysql" ]] && [[ "$db" != "performance_schema" ]] && [[ "$db" != "information_schema" ]]; then
        echo "Backing up database: $db"
        FILENAME="${TODAYS_BACKUP_DIR}${db}_${TIME}.sql.gz"
        $MYSQL_DIR/mysqldump --user="$SQL_USER" --password="$SQL_PASS" --opt --routines --force --databases $db | gzip > "$FILENAME"
        
        # Verify the backup was created
        if [ -f "$FILENAME" ]; then
            echo "Successfully created: $FILENAME"
        else
            echo "ERROR: Failed to create backup for $db" >&2
        fi
    fi
done

echo "Backup completed at $(date)"