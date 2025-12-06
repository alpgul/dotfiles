#!/bin/bash

# SOPS ve GPG kurulum script'i - Environment variable destekli
# Bu dosyayı .devcontainer/setup-sops.sh olarak kaydedin

set -e

# Script'in bulunduğu dizini al
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Proje dizinine git (script'in bir üst dizini)
cd "$SCRIPT_DIR/.."

echo "🔧 SOPS ve GPG kurulumu başlıyor..."

# SOPS'i yükle
echo "📦 SOPS yükleniyor..."
sudo apt-get update
sudo apt-get install -y curl gnupg2 gettext-base

# SOPS'i indir ve kur
SOPS_VERSION=$(curl -s https://api.github.com/repos/getsops/sops/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -L -o sops "https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.amd64"
chmod +x sops
sudo mv sops /usr/local/bin/

echo "✅ SOPS başarıyla yüklendi: $(sops --version)"
echo "✅ envsubst (gettext-base) başarıyla yüklendi"

# GPG yapılandırması
echo "🔐 GPG yapılandırılıyor..."
mkdir -p ~/.gnupg
chmod 700 ~/.gnupg

# Environment variable'dan GPG anahtarları ile kurulum dene
if [ -n "$GPG_PRIVATE_KEY" ] && [ -n "$GPG_PUBLIC_KEY" ] && [ -n "$GPG_KEY_ID" ]; then
    echo "🔑 Environment variable'dan GPG anahtarları import ediliyor..."
    
    # Public key'i import et
    echo "$GPG_PUBLIC_KEY" | base64 -d | gpg --import
    
    # Private key'i import et
    echo "$GPG_PRIVATE_KEY" | base64 -d | gpg --import
    
    # Anahtarı güvenli hale getir
    echo -e "5\ny\n" | gpg --command-fd 0 --edit-key "$GPG_KEY_ID" trust
    
    echo "✅ GPG anahtarları başarıyla import edildi"
else
    echo "⚠️  GPG environment variable'ları bulunamadı"
    echo "ℹ️  Gerekli environment variable'lar:"
    echo "   - GPG_PRIVATE_KEY (base64 encoded)"
    echo "   - GPG_PUBLIC_KEY (base64 encoded)"
    echo "   - GPG_KEY_ID"
    echo ""
    echo "   './create-gpg.sh' script'ini çalıştırarak yeni anahtar oluşturabilirsiniz"
fi

# Git filter'larının çalışıp çalışmadığını test et
echo "🧪 Git filter'ları test ediliyor..."

# Git konfigürasyonunu ekle
echo "🔧 Git konfigürasyonu ayarlanıyor..."
git config --local include.path .gitconfig

if git config --get filter.sops.clean > /dev/null 2>&1; then
    echo "✅ SOPS filter'ları başarıyla yapılandırıldı"
else
    echo "❌ SOPS filter'ları yapılandırılamadı"
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
   export GPG_KEY_ID="YOUR_KEY_ID"

3. Veya .env dosyasına ekleyin (GİT'E EKLEMEYİN!):
   GPG_PRIVATE_KEY=your-base64-private-key
   GPG_PUBLIC_KEY=your-base64-public-key
   GPG_KEY_ID=your-key-id

4. GitHub Actions/Codespaces için:
   Repository → Settings → Secrets → New secret
   Name: GPG_PRIVATE_KEY, GPG_PUBLIC_KEY, GPG_KEY_ID

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

echo ""
echo "✨ Kurulum tamamlandı!"