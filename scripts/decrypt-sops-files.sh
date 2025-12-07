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

log "Çalışma dizini: $(pwd)"
log "Proje kökü: $PROJECT_ROOT"
log ".gitattributes dosyası kontrol ediliyor: $(pwd)/.gitattributes"

# .gitattributes dosyasından sops filter'ı olan dizinleri bul
log ".gitattributes dosyasından sops dizinleri okunuyor..."

# .gitattributes dosyasının varlığını kontrol et
if [ ! -f .gitattributes ]; then
    log "HATA: .gitattributes dosyası bulunamadı"
    echo "❌ .gitattributes dosyası bulunamadı"
    exit 1
fi

# Dosya içeriğini önce bir değişkene oku
log ".gitattributes dosyası içeriği okunuyor..."
gitattributes_content=$(cat .gitattributes)
log "Dosya içeriği başarıyla okundu"

# Satır satır işle
echo "$gitattributes_content" | while IFS= read -r line; do
    # Boş satırları ve yorumları atla
    if [[ -z "$line" || "$line" == \#* ]]; then
        log "Boş satır veya yorum atlandı: $line"
        continue
    fi
    
    log "İşlenen satır: $line"
    
    # filter=sops içeren satırları bul
    if [[ "$line" == *"filter=sops"* ]]; then
        log "filter=sops içeren satır bulundu: $line"
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
            
            # Dosyayı decrypt et ve dosyaya yaz
            if sops decrypt "$file" > "$file.decrypted" 2>/dev/null; then
                # Decrypt edilen dosyayı orijinal dosyanın üzerine kopyala
                mv "$file.decrypted" "$file"
                log "Dosya decrypt edildi: $file"
            else
                # Geçici dosya varsa temizle
                rm -f "$file.decrypted"
                log "Dosya zaten decrypted veya decrypt edilemedi: $file"
            fi
        done
    else
        log "filter=sops içermeyen satır atlandı: $line"
    fi
done

log "Tüm dosyalar işlendi."