#!/bin/bash

# GPG anahtarı oluşturma script'i
# Kullanım: ./create-gpg.sh

set -e

# Script'in bulunduğu dizini al
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Proje dizinine git (script'in bir üst dizini)
cd "$SCRIPT_DIR/.."

echo "🔐 GPG Key Creation Tool for SOPS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# GPG kontrol et
if ! command -v gpg &> /dev/null; then
    echo "❌ Hata: GPG kurulu değil!"
    echo "Lütfen önce GPG kurun:"
    echo "  Ubuntu/Debian: sudo apt-get install gnupg2"
    echo "  macOS: brew install gnupg"
    exit 1
fi

# Git repository kontrol et
if [ ! -d ".git" ]; then
    echo "❌ Hata: Bu bir Git repository değil!"
    echo "Lütfen Git repository içinde çalışın."
    exit 1
fi

echo "📋 Git repository kontrol edildi..."
echo ""

# GPG dizinini oluştur
mkdir -p ~/.gnupg
chmod 700 ~/.gnupg

# Random kullanıcı bilgileri oluştur
RANDOM_NAME="SOPS User $(date +%s)"
RANDOM_EMAIL="sops-$(date +%s)@example.local"

echo "👤 Random kullanıcı bilgileri oluşturuluyor:"
echo "   Name: $RANDOM_NAME"
echo "   Email: $RANDOM_EMAIL"
echo ""

# GPG anahtarı oluştur
echo "🔑 GPG anahtarı oluşturuluyor..."
gpg --batch --gen-key << EOF
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: DOTFILES
Name-Email: dotfiles@example.local
Expire-Date: 0
%no-protection
EOF

echo "✅ GPG anahtarı başarıyla oluşturuldu!"
echo ""

# Anahtar ID'sini al (sadece bilgi için)
TEMP_KEY_ID=$(gpg --list-secret-keys --keyid-format LONG | grep sec | awk '{print $2}' | cut -d'/' -f2 | head -1)
echo "🔍 Oluşturulan anahtar ID: $TEMP_KEY_ID"
echo ""

# Public key'i export et (DOTFILES olarak)
echo "📤 Public key export ediliyor..."
GPG_PUBLIC_KEY=$(gpg --armor --export "E784D2C44FEFD7561B773DD1CC997FB203A5117C" | base64 -w 0)

# Private key'i export et (DOTFILES olarak)
echo "📤 Private key export ediliyor..."
GPG_PRIVATE_KEY=$(gpg --armor --export-secret-key "E784D2C44FEFD7561B773DD1CC997FB203A5117C" | base64 -w 0)

echo "✅ Anahtarlar başarıyla export edildi!"
echo ""

# Secrets değerlerini dosyaya yaz
SECRETS_FILE=".gpg-secrets"
cat > "$SECRETS_FILE" << EOF
# GPG Secrets Information
# Generated: $(date)
# ⚠️  BU DOSYAYI GIT'E EKLEMEYİN! (.gitignore'a ekleyin)

# GPG Key Information
GPG_KEY_NAME="$RANDOM_NAME"
GPG_KEY_EMAIL="$RANDOM_EMAIL"

# GPG Keys (Base64 encoded)
GPG_PUBLIC_KEY=$GPG_PUBLIC_KEY
GPG_PRIVATE_KEY=$GPG_PRIVATE_KEY

# Export Commands (for manual usage)
export GPG_PUBLIC_KEY="$GPG_PUBLIC_KEY"
export GPG_PRIVATE_KEY="$GPG_PRIVATE_KEY"

# Kontrol komutu
# Oluşturulan anahtarı kontrol etmek için: gpg --list-keys "DOTFILES"
EOF

echo "✅ Secrets dosyası oluşturuldu: $SECRETS_FILE"
echo ""

echo "🎉 Hazır! Artık SOPS ile şifreli dosyalarınızı kullanabilirsiniz."