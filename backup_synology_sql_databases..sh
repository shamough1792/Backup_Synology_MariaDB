#!/bin/bash
# backup_sql_databases.sh
#
# Synology-compatible MySQL/MariaDB backup script

############
# Settings #
############

BACKUP_DIR="/Path_To_Backup/"
DAYS_KEEP=4  # Number of days to keep backups
SQL_USER="root"
SQL_PASS="Your_DB_Password"
MYSQL_DIR="/volume1/@appstore/MariaDB10/usr/local/mariadb10/bin/"
BACKUP_OWNER="$(whoami)"  # Or set to specific Synology user like "admin"

#############
# Main part #
#############

# Create backup directory with proper permissions
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H%M)
TODAYS_BACKUP_DIR="${BACKUP_DIR}${DATE}/"

mkdir -p "$TODAYS_BACKUP_DIR"
chown "$BACKUP_OWNER" "$TODAYS_BACKUP_DIR"
chmod 750 "$TODAYS_BACKUP_DIR"

# Improved old backup cleanup
echo "Cleaning up backups older than $DAYS_KEEP days..."
find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d -name "20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]" -mtime +$DAYS_KEEP -print0 | while IFS= read -r -d '' dir; do
    echo "Deleting old backup: $dir"
    rm -rf "$dir"
done

# Get list of databases
databases=$("${MYSQL_DIR}mysql" --user="$SQL_USER" --password="$SQL_PASS" -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql|sys)")

# Backup each database
for db in $databases; do
    echo "Backing up database: $db"
    FILENAME="${TODAYS_BACKUP_DIR}${db}_${TIME}.sql.gz"
    
    if "${MYSQL_DIR}mysqldump" --user="$SQL_USER" --password="$SQL_PASS" --opt --routines --force --databases "$db" | gzip > "$FILENAME"; then
        chown "$BACKUP_OWNER" "$FILENAME"
        chmod 640 "$FILENAME"
        echo "Successfully created: $FILENAME"
    else
        echo "ERROR: Failed to create backup for $db" >&2
        rm -f "$FILENAME"
    fi
done

echo "Backup completed at $(date)"
