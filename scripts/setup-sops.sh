#!/bin/bash

# SOPS ve GPG kurulum script'i - Environment variable destekli
# Bu dosyayı .devcontainer/setup-sops.sh olarak kaydedin

set -e

# Script'in bulunduğu dizini al
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Proje dizinine git (script'in bir üst dizini)
cd "$SCRIPT_DIR/.."

# Loglama fonksiyonu
log() {
    local log_dir="$SCRIPT_DIR/../logs"
    local log_file="$log_dir/setup-sops.log"
    
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
        log "HATA: Hata mesajı: $(eval "$command" 2>&1 | tail -5)"
    fi
}

# Hata yakalamayı ayarla
set -eE
trap 'log_error "$BASH_COMMAND" "$LINENO"' ERR

log "SOPS ve GPG kurulumu başlatılıyor..."
echo "🔧 SOPS ve GPG kurulumu başlıyor..."

# SOPS'i yükle
log "SOPS ve bağımlılıkları yükleniyor..."
echo "📦 SOPS yükleniyor..."
sudo apt-get update
sudo apt-get install -y curl gnupg2 gettext-base

# SOPS'i indir ve kur
SOPS_VERSION=$(curl -s https://api.github.com/repos/getsops/sops/releases/latest | grep '"tag_name":' | cut -d '"' -f 4)
log "SOPS versiyonu belirleniyor: ${SOPS_VERSION}"
echo "📥 SOPS ${SOPS_VERSION} indiriliyor..."

# Eğer versiyon alınamazsa varsayılan bir versiyon kullan
if [ -z "$SOPS_VERSION" ]; then
    log "SOPS versiyonu alınamadı, varsayılan versiyon kullanılacak: v3.8.1"
    echo "⚠️  SOPS versiyonu alınamadı, varsayılan versiyon kullanılacak..."
    SOPS_VERSION="v3.8.1"
fi

curl -L -o sops "https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.amd64"

# İndirilen dosyanın boş olup olmadığını kontrol et
if [ ! -s sops ]; then
    log "SOPS indirilemedi veya dosya boş, alternatif yöntem deneniyor"
    echo "❌ SOPS indirilemedi veya dosya boş!"
    echo "Alternatif olarak manuel kurulum denenecek..."
    # Alternatif kurulum yöntemi
    wget -O sops "https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.amd64"
fi

# Dosyanın binary olduğunu kontrol et
if file sops | grep -q "ASCII"; then
    log "İndirilen dosya binary değil, hata var"
    echo "❌ İndirilen dosya binary değil, hata var!"
    echo "İçerik:"
    head -5 sops
    exit 1
fi

chmod +x sops
sudo mv sops /usr/local/bin/

SOPS_INSTALLED_VERSION=$(sops --version)
log "SOPS başarıyla yüklendi: ${SOPS_INSTALLED_VERSION}"
echo "✅ SOPS başarıyla yüklendi: ${SOPS_INSTALLED_VERSION}"
echo "✅ envsubst (gettext-base) başarıyla yüklendi"

# GPG yapılandırması
log "GPG yapılandırması başlatılıyor..."
echo "🔐 GPG yapılandırılıyor..."
mkdir -p ~/.gnupg
chmod 700 ~/.gnupg

# Environment variable'dan GPG anahtarları ile kurulum dene
if [ -n "$GPG_PRIVATE_KEY" ] && [ -n "$GPG_PUBLIC_KEY" ]; then
    log "Environment variable'dan GPG anahtarları import ediliyor..."
    echo "🔑 Environment variable'dan GPG anahtarları import ediliyor..."
    
    # Public key'i import et
    echo "$GPG_PUBLIC_KEY" | base64 -d | gpg --import
    
    # Private key'i import et
    echo "$GPG_PRIVATE_KEY" | base64 -d | gpg --import
    
    # Her zaman DOTFILES olarak kullan
    GPG_KEY_ID="F09CDCB0DBC34F6F"
    
    # Anahtarı güvenli hale getir
    echo -e "5\ny\n" | gpg --command-fd 0 --edit-key "$GPG_KEY_ID" trust
    
    log "GPG anahtarları başarıyla import edildi (Key ID: ${GPG_KEY_ID})"
    echo "✅ GPG anahtarları başarıyla import edildi (Key ID: $GPG_KEY_ID)"
else
    log "GPG environment variable'ları bulunamadı"
    echo "⚠️  GPG environment variable'ları bulunamadı"
    echo "ℹ️  Gerekli environment variable'lar:"
    echo "   - GPG_PRIVATE_KEY (base64 encoded)"
    echo "   - GPG_PUBLIC_KEY (base64 encoded)"
    echo ""
    echo "   './create-gpg.sh' script'ini çalıştırarak yeni anahtar oluşturabilirsiniz"
fi

# Git filter'larının çalışıp çalışmadığını test et
log "Git filter'ları test ediliyor..."
echo "🧪 Git filter'ları test ediliyor..."

# Git konfigürasyonunu ekle
log "Git konfigürasyonu ayarlanıyor..."
echo "🔧 Git konfigürasyonu ayarlanıyor..."

# Git konfigürasyonu için dizin kontrolü
GIT_CONFIG_PATH="/workspaces/.codespaces/.persistedshare/dotfiles"
if [ -d "$GIT_CONFIG_PATH" ]; then
    log "Git dizini bulundu: ${GIT_CONFIG_PATH}"
    
    # Git konfigürasyon komutunu çalıştır ve sonucu logla
    log "Git konfigürasyon komutu çalıştırılıyor: git -C ${GIT_CONFIG_PATH} config --local include.path ${GIT_CONFIG_PATH}/.gitconfig"
    
    if git -C "$GIT_CONFIG_PATH" config --local include.path "$GIT_CONFIG_PATH/.gitconfig" 2>&1; then
        log "Git konfigürasyon komutu başarıyla çalıştırıldı"
        
        # Konfigürasyonun doğru ayarlandığını kontrol et
        if git -C "$GIT_CONFIG_PATH" config --get --local include.path 2>/dev/null; then
            log "Git konfigürasyonu doğrulandı: $(git -C "$GIT_CONFIG_PATH" config --get --local include.path)"
        else
            log "UYARI: Git konfigürasyonu ayarlandı ancak doğrulanamadı"
        fi
    else
        log "HATA: Git konfigürasyon komutu başarısız oldu"
        echo "❌ Git konfigürasyonu ayarlanamadı"
    fi
else
    log "HATA: Git dizini bulunamadı: ${GIT_CONFIG_PATH}"
    echo "❌ Git dizini bulunamadı: $GIT_CONFIG_PATH"
fi

# SOPS filter'larının çalışıp çalışmadığını test et
log "SOPS filter'ları kontrol ediliyor..."
if git config --get filter.sops.clean > /dev/null 2>&1; then
    log "SOPS filter'ları başarıyla yapılandırıldı"
    echo "✅ SOPS filter'ları başarıyla yapılandırıldı"
else
    log "SOPS filter'ları yapılandırılamadı"
    echo "❌ SOPS filter'ları yapılandırılamadı"
    
    # Mevcut git konfigürasyonunu logla
    log "Mevcut git konfigürasyonu:"
    git config --list 2>&1 | while read -r line; do
        log "  $line"
    done
fi

# Kullanım bilgileri
cat << 'EOF'

📚 SOPS + Git Filters Kullanım Kılavuzu:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔐 GPG Anahtarlarını Environment Variable Olarak Kaydetme:

1. Anahtar oluşturmak için:
   ./create-gpg.sh

2. Oluşturulan anahtarları environment variable'a ekleyin:
 export GPG_PRIVATE_KEY="YOUR_BASE64_ENCODED_PRIVATE_KEY"
 export GPG_PUBLIC_KEY="YOUR_BASE64_ENCODED_PUBLIC_KEY"

3. Veya .env dosyasına ekleyin (GİT'E EKLEMEYİN!):
 GPG_PRIVATE_KEY=your-base64-private-key
 GPG_PUBLIC_KEY=your-base64-public-key

4. GitHub Actions/Codespaces için:
 Repository → Settings → Secrets → New secret
 Name: GPG_PRIVATE_KEY, GPG_PUBLIC_KEY

🔒 SOPS Git Filters ile Otomatik Şifreleme:
   • Git add/push: Dosyalar otomatik şifrelenir
   • Git checkout/clone: Dosyalar otomatik çözülür
   • Manuel: sops --encrypt/decrypt komutları

🚀 İlk Kurulum:
   1. ./create-gpg.sh
   2. git add . && git commit && git push

🔓 Başka Makinede:
   Environment variable'ları ayarlayın, container başlatın!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

log "Kurulum tamamlandı"
echo ""
echo "✨ Kurulum tamamlandı!"