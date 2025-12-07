#!/bin/bash
# scripts/sops-clean-filter.sh

# Betik dizinini al ve proje köküne git
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Loglama fonksiyonu
log() {
    local log_dir="$PROJECT_ROOT/logs"
    local log_file="$log_dir/sops-clean-filter.log"
    
    # Log dizinini oluştur (yoksa)
    mkdir -p "$log_dir"
    
    # Zaman damgası ile log kaydı
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$log_file"
}

# Hata yakalama fonksiyonu
log_error() {
    local exit_code=$?
    local command="$1"
    local line_number=$2
    
    if [ $exit_code -ne 0 ]; then
        log "HATA: Komut başarısız oldu (çıkış kodu: $exit_code)"
        log "HATA: Komut: $command"
        log "HATA: Satır: $line_number"
        log "HATA: Dosya: $1"
    fi
}

# Hata yakalamayı ayarla
set -eE
trap 'log_error "$BASH_COMMAND" "$LINENO" "$1"' ERR


# Eğer standart girdi boşsa ve dosya varsa, dosyadan oku
if [ -t 0 ] && [ -f "$1" ]; then
    content="$(cat "$1")"
else
    content="$(cat -)"
fi

# İçerik zaten decrypted olarak geliyor
decrypted_content="$content"
# HEAD'de dosya var mı?
if git cat-file -e "HEAD:$1" 2>/dev/null; then
    log "HEAD'de mevcut dosya işleniyor: $1"
    # HEAD'deki içeriği al
    head_content="$(git cat-file -p "HEAD:$1")"
    
    # HEAD'i decrypt et (başarısızsa olduğu gibi kullan)
    head_decrypted="$(echo "$head_content" | sops decrypt --filename-override "$1" 2>/dev/null || echo "$head_content")"
    
    # İçerik aynı mı?
    if diff <(echo "$decrypted_content") <(echo "$head_decrypted") >/dev/null 2>&1; then
        # Aynı - HEAD'i döndür
        log "İçerik aynı, HEAD sürümü kullanılıyor: $1"
        echo "$head_content"
    else
        # Farklı - şifrele ve dosyaya yaz
        log "İçerik farklı, şifreleniyor: $1"
        encrypted_content="$(sops encrypt --filename-override "$1" <<<"$decrypted_content")"
        echo "$encrypted_content" > "$1"
    fi
else
    # Yeni dosya - şifrele ve dosyaya yaz
    log "Yeni dosya işleniyor: $1"
    log "Yeni dosya şifreleniyor: $1"
    encrypted_content="$(sops encrypt --filename-override "$1" <<<"$decrypted_content")"
    echo "$encrypted_content" > "$1"
fi