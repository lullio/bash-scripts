#!/bin/bash

# ══ CONFIGURAÇÕES ══════════════════════════════════════════════
DATE_STAMP=$(date '+%Y-%m-%d--%H-%M-%S')
TODAY=$(date +%F)

BACKUP_DIR="$HOME/backups/websites"
BACKUP_FILES=( "/var/www" ) 
# BACKUP_FILES=("/home/" "/var/www/html" "/var/lib/mysql" "/etc" "/boot" "/root")
LOG_FILE="$BACKUP_DIR/backups.log"

# retenção local em dias
MAX_BACKUPS=5

# remotes configurados no rclone
REMOTE_GDRIVE="gdrive-lullinho30"
REMOTE_ONEDRIVE="onedrive-lullio.com.br"
REMOTE_PATH="websites"   # pasta base no remote

# parâmetros de paralelismo para rclone
TRANSFERS=4
CHECKERS=8
# ══ FIM CONFIGURAÇÕES ══════════════════════════════════════════

set -euo pipefail

init() {
  mkdir -p "$BACKUP_DIR"
}

do_sites_backup() {
  local backup_name="sites-${DATE_STAMP}.tar.gz"
  echo "[INFO] Criando backup: $backup_name"
  tar \
    --exclude="$BACKUP_DIR" \
    -cvzpf "$BACKUP_DIR/$backup_name" \
    "${BACKUP_FILES[@]}"
}

do_db_backup() {
  local all_dbs="databases-${DATE_STAMP}.sql"
  local wp_db="wp_dropshippingal-${DATE_STAMP}.sql"
  echo "[INFO] Dump de todas as bases MariaDB: $all_dbs"
  mysqldump -A > "$BACKUP_DIR/$all_dbs"
  # Sem -p, sem prompt: credenciais em ~/.my.cnf
  echo "[INFO] Dump da base wp_dropshippingal: $wp_db"
  mysqldump wp_dropshippingal > "$BACKUP_DIR/$wp_db"
}

upload_backups() {
  local src="$BACKUP_DIR"
  local dest_gd="${REMOTE_GDRIVE}:${REMOTE_PATH}/${TODAY}"
  local dest_od="${REMOTE_ONEDRIVE}:${REMOTE_PATH}/${TODAY}"

  echo "[INFO] Sincronizando para Google Drive em $dest_gd"
  rclone sync "$src" "$dest_gd" \
    --create-empty-src-dirs \
    --transfers $TRANSFERS \
    --checkers $CHECKERS \
    --skip-links \
    --delete-excluded

  echo "[INFO] Sincronizando para OneDrive em $dest_od"
  rclone sync "$src" "$dest_od" \
    --create-empty-src-dirs \
    --transfers $TRANSFERS \
    --checkers $CHECKERS \
    --skip-links \
    --delete-excluded
}

cleanup_local() {
  echo "[INFO] Removendo backups locais com mais de $MAX_BACKUPS dias"
  find "$BACKUP_DIR" -type f -mtime +"$MAX_BACKUPS" -delete
}

write_log() {
  {
    echo "=== Início: $(date '+%F %T') ==="
    echo "Backups criados:"
    ls -1 "$BACKUP_DIR" | grep -E "${TODAY}"
    echo "=== Fim:    $(date '+%F %T') ==="
    echo
  } >> "$LOG_FILE"
  echo "[INFO] Log atualizado em $LOG_FILE"
}

main() {
  init
  do_sites_backup
  do_db_backup
  upload_backups
  #cleanup_local
  write_log
  echo "[OK] Backup concluído com sucesso!"
}

main "$@"