#!/bin/bash
# scripts/sops-clean-filter.sh

content="$(cat -)"

# Loglama fonksiyonu
log() {
    local log_dir="$(dirname "$0")/../logs"
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

is_encrypted() {
    echo "$1" | grep -q "sops"
}

# HEAD'de dosya var mı?
if git cat-file -e "HEAD:$1" 2>/dev/null; then
    log "HEAD'de mevcut dosya işleniyor: $1"
    # HEAD'deki içeriği al
    head_content="$(git cat-file -p "HEAD:$1")"
    
    # HEAD'i decrypt et (başarısızsa olduğu gibi kullan)
    head_decrypted="$(echo "$head_content" | sops decrypt --filename-override "$1" 2>/dev/null || echo "$head_content")"
    
    # İçerik aynı mı?
    if diff <(echo "$content") <(echo "$head_decrypted") >/dev/null 2>&1; then
        # Aynı - HEAD'i döndür
        log "İçerik aynı, HEAD sürümü kullanılıyor: $1"
        echo "$head_content"
    else
        # Farklı - şifreli mi kontrol et
        if is_encrypted "$content"; then
            # Zaten şifreli
            log "İçerik farklı ve zaten şifreli: $1"
            echo "$content"
        else
            # Şifrele
            log "İçerik farklı ve şifresiz, şifreleniyor: $1"
            sops encrypt --filename-override "$1" <<<"$content"
        fi
    fi
else
    # Yeni dosya - şifreli mi kontrol et
    log "Yeni dosya işleniyor: $1"
    if is_encrypted "$content"; then
        # Zaten şifreli
        log "Yeni dosya zaten şifreli: $1"
        echo "$content"
    else
        # Şifrele
        log "Yeni dosya şifreleniyor: $1"
        sops encrypt --filename-override "$1" <<<"$content"
    fi
fi