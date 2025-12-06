#!/bin/bash
# scripts/sops-clean-filter.sh

content="$(cat -)"

is_encrypted() {
    echo "$1" | grep -q "sops"
}

# HEAD'de dosya var mı?
if git cat-file -e "HEAD:$1" 2>/dev/null; then
    # HEAD'deki içeriği al
    head_content="$(git cat-file -p "HEAD:$1")"
    
    # HEAD'i decrypt et (başarısızsa olduğu gibi kullan)
    head_decrypted="$(echo "$head_content" | sops decrypt --filename-override "$1" 2>/dev/null || echo "$head_content")"
    
    # İçerik aynı mı?
    if diff <(echo "$content") <(echo "$head_decrypted") >/dev/null 2>&1; then
        # Aynı - HEAD'i döndür
        echo "$head_content"
    else
        # Farklı - şifreli mi kontrol et
        if is_encrypted "$content"; then
            # Zaten şifreli
            echo "$content"
        else
            # Şifrele
            sops encrypt --filename-override "$1" <<<"$content"
        fi
    fi
else
    # Yeni dosya - şifreli mi kontrol et
    if is_encrypted "$content"; then
        # Zaten şifreli
        echo "$content"
    else
        # Şifrele
        sops encrypt --filename-override "$1" <<<"$content"
    fi
fi