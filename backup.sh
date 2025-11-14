#!/bin/bash
# ======================================
# 🧠 Backup e Restore do Ambiente N8N + RabbitMQ + PostgreSQL
# ======================================

BASE_DIR="$(dirname "$(realpath "$0")")"
BACKUP_DIR="$BASE_DIR/backup"
DATE=$(date +'%Y-%m-%d_%H-%M-%S')

mkdir -p "$BACKUP_DIR"

usage() {
  echo "Uso:"
  echo "  ./backup.sh backup     → cria backup completo"
  echo "  ./backup.sh restore <arquivo>  → restaura backup"
  exit 1
}

# ======================================
# 🔹 FUNÇÃO DE BACKUP
# ======================================
backup() {
  BACKUP_FILE="$BACKUP_DIR/n8n_backup_$DATE.tar.gz"

  echo "📦 Iniciando backup do ambiente N8N + RabbitMQ + PostgreSQL"
  echo "→ Dump do banco de dados PostgreSQL..."
  docker exec -t postgres pg_dump -U n8nuser n8n > "$BACKUP_DIR/n8n_postgres_$DATE.sql"

  echo "→ Compactando arquivos..."
  tar -czf "$BACKUP_FILE" \
    -C "$BASE_DIR" .n8n \
    -C "$BASE_DIR" postgres_data \
    -C "$BACKUP_DIR" "n8n_postgres_$DATE.sql" \
    -C "$BASE_DIR" n8n.crt \
    -C "$BASE_DIR" n8n.key

  rm "$BACKUP_DIR/n8n_postgres_$DATE.sql"

  echo "✅ Backup concluído: $BACKUP_FILE"

  # limpa backups antigos (opcional: +7 dias)
  find "$BACKUP_DIR" -type f -mtime +7 -name "n8n_backup_*.tar.gz" -delete
}

# ======================================
# 🔹 FUNÇÃO DE RESTORE
# ======================================
restore() {
  if [ -z "$1" ]; then
    echo "❌ Erro: você precisa informar o arquivo de backup."
    echo "Exemplo: ./backup.sh restore backup/n8n_backup_2025-11-13_12-00-00.tar.gz"
    exit 1
  fi

  BACKUP_FILE="$1"

  if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Arquivo de backup não encontrado: $BACKUP_FILE"
    exit 1
  fi

  echo "♻️ Restaurando ambiente a partir de: $BACKUP_FILE"

  echo "→ Parando containers..."
  docker compose down

  echo "→ Limpando dados antigos..."
  rm -rf "$BASE_DIR/.n8n" "$BASE_DIR/postgres_data"

  echo "→ Extraindo arquivos do backup..."
  tar -xzf "$BACKUP_FILE" -C "$BASE_DIR"

  echo "→ Subindo containers..."
  docker compose up -d

  sleep 10

  echo "→ Restaurando banco de dados..."
  docker exec -i postgres psql -U n8nuser n8n < "$BACKUP_DIR"/n8n_postgres_*.sql 2>/dev/null || echo "⚠️ Dump SQL não encontrado (provavelmente incluso no tar)."

  echo "✅ Restore concluído com sucesso!"
}

# ======================================
# 🚀 EXECUÇÃO
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