#!/bin/bash
# ======================================
# 🧠 Backup and Restore for N8N + RabbitMQ + PostgreSQL Environment
# ======================================

BASE_DIR="$(dirname "$(realpath "$0")")"
BACKUP_DIR="$BASE_DIR/backup"
DATE=$(date +'%Y-%m-%d_%H-%M-%S')

mkdir -p "$BACKUP_DIR"

usage() {
  echo "Usage:"
  echo "  ./backup.sh backup            → creates a full backup"
  echo "  ./backup.sh restore <file>    → restores from a backup"
  exit 1
}

# ======================================
# 🔹 BACKUP FUNCTION
# ======================================
backup() {
  BACKUP_FILE="$BACKUP_DIR/n8n_backup_$DATE.tar.gz"

  echo "📦 Starting backup of N8N + RabbitMQ + PostgreSQL environment"
  echo "→ Dumping PostgreSQL database..."
  docker exec -t postgres pg_dump -U n8nuser n8n > "$BACKUP_DIR/n8n_postgres_$DATE.sql"

  echo "→ Compressing files..."
  tar -czf "$BACKUP_FILE" \
    -C "$BASE_DIR" .n8n \
    -C "$BASE_DIR" postgres_data \
    -C "$BACKUP_DIR" "n8n_postgres_$DATE.sql" \
    -C "$BASE_DIR" n8n.crt \
    -C "$BASE_DIR" n8n.key

  rm "$BACKUP_DIR/n8n_postgres_$DATE.sql"

  echo "✅ Backup complete: $BACKUP_FILE"

  # Cleanup old backups (optional: older than 7 days)
  find "$BACKUP_DIR" -type f -mtime +7 -name "n8n_backup_*.tar.gz" -delete
}

# ======================================
# 🔹 RESTORE FUNCTION
# ======================================
restore() {
  if [ -z "$1" ]; then
    echo "❌ Error: you must specify a backup file."
    echo "Example: ./backup.sh restore backup/n8n_backup_2025-11-13_12-00-00.tar.gz"
    exit 1
  fi

  BACKUP_FILE="$1"

  if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Backup file not found: $BACKUP_FILE"
    exit 1
  fi

  echo "♻️ Restoring environment from: $BACKUP_FILE"

  echo "→ Stopping containers..."
  docker compose down

  echo "→ Cleaning old data..."
  rm -rf "$BASE_DIR/.n8n" "$BASE_DIR/postgres_data"

  echo "→ Extracting files from backup..."
  tar -xzf "$BACKUP_FILE" -C "$BASE_DIR"

  echo "→ Starting containers..."
  docker compose up -d

  sleep 10

  echo "→ Restoring database..."
  docker exec -i postgres psql -U n8nuser n8n < "$BACKUP_DIR"/n8n_postgres_*.sql 2>/dev/null || echo "⚠️ SQL dump not found (probably included in the tar)."

  echo "✅ Restore completed successfully!"
}

# ======================================
# 🚀 EXECUTION
# ======================================
case "$1" in
  backup)
    backup
    ;;
  restore)
    restore "$2"
    ;;
  *)
    usage
    ;;
esac