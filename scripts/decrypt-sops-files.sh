#!/bin/bash
# scripts/decrypt-sops-files.sh

# Betik dizinini al ve proje köküne git
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Loglama fonksiyonu
log() {
    local log_dir="$PROJECT_ROOT/logs"
    local log_file="$log_dir/decrypt-sops-files.log"
    
    # Log dizinini oluştur (yoksa)
    mkdir -p "$log_dir"
    
    # Zaman damgası ile log kaydı
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$log_file"
}

# .gitattributes dosyasından sops filter'ı olan dizinleri bul
log ".gitattributes dosyasından sops dizinleri okunuyor..."
while IFS= read -r line; do
    # Boş satırları ve yorumları atla
    if [[ -z "$line" || "$line" == \#* ]]; then
        continue
    fi
    
    # filter=sops içeren satırları bul
    if [[ "$line" == *"filter=sops"* ]]; then
        # Path kısmını al (filter=sops diff=sops kısmını kaldır)
        path_pattern=$(echo "$line" | awk '{print $1}')
        # Başındaki / karakterini kaldır
        path_pattern=${path_pattern#/}
        
        log "Sops dizini bulundu: $path_pattern"
        
        # Bu patterne uyan dosyaları bul ve decrypt et
        find . -path "./$path_pattern" -type f | while read -r file; do
            # .git dizinini atla
            if [[ "$file" == ./.git/* ]]; then
                continue
            fi
            
            log "Dosya işleniyor: $file"
            
            # Dosyayı decrypt et (başarısızsa atla)
            if sops decrypt --filename-override "$file" "$file" 2>/dev/null; then
                log "Dosya decrypt edildi: $file"
            else
                log "Dosya zaten decrypted veya decrypt edilemedi: $file"
            fi
        done
    fi
done < .gitattributes

log "Tüm dosyalar işlendi."