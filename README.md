# VSCode Dotfiles Manager

VSCode konfigürasyonlarınızı yönetmek için basit ve etkili bir dotfiles sistemi. Farklı geliştirme profilleri arasında kolayca geçiş yapmanızı sağlar.

## 🚀 Özellikler

- **Çoklu Profil Desteği**: Farklı geliştirme ortamları için önceden yapılandırılmış profiller
- **Interaktif Kurulum**: Kullanıcı dostu komut satırı arayüzü
- **Otomatik Yedekleme**: Mevcut ayarlarınızın güvenliğini sağlar
- **Esnek Kurulum**: Sadece ayarlar, sadece uzantılar veya tam kurulum seçenekleri
- **Çapraz Platform**: Linux, macOS ve Windows desteği

## 📁 Proje Yapısı

```
dotfiles/
├── vscode/
│   ├── profiles/
│   │   ├── web-development/     # Web geliştirme profili
│   │   ├── python-development/  # Python geliştirme profili
│   │   └── minimal/             # Minimal profil
│   └── profiles.json            # Profillerin meta bilgileri
├── scripts/
│   ├── import-profile.sh        # Profil içe aktarma script'i
│   ├── import-extensions.sh     # Uzantı yükleme script'i
│   └── utils.sh                 # Yardımcı fonksiyonlar
├── install.sh                   # Ana kurulum script'i
└── README.md                    # Bu dosya
```

## 🎯 Mevcut Profiller

### 1. Web Development Profile
Web geliştirme için tam donanımlı profil:
- **Ayarlar**: HTML, CSS, JavaScript, React, Tailwind CSS optimizasyonları
- **Uzantılar**: Live Server, ESLint, Prettier, GitLens, Docker ve daha fazlası
- **Kısayollar**: Web geliştirme için optimize edilmiş klavye kısayolları

### 2. Python Development Profile
Python geliştirme için optimize edilmiş profil:
- **Ayarlar**: Python, Django, Flask, Data Science, Jupyter optimizasyonları
- **Uzantılar**: Python, Pylint, Black, Jupyter, Docker ve daha fazlası
- **Kısayollar**: Python geliştirme için özel kısayollar

### 3. Minimal Profile
Minimal ve temiz VSCode deneyimi:
- **Ayarlar**: Temel VSCode ayarları, minimum özellik
- **Uzantılar**: Sadece temel JSON desteği
- **Kısayollar**: Esas klavye kısayolları

## 🛠️ Kurulum

### Hızlı Başlangıç

1. Bu repoyu klonlayın:
```bash
git clone https://github.com/kullanici/dotfiles.git
cd dotfiles
```

2. Kurulum script'ini çalıştırın:
```bash
./install.sh
```

3. İstediğiniz profili seçin ve kurulumu tamamlayın!

### Detaylı Kurulum Seçenekleri

#### Interaktif Kurulum
```bash
./install.sh
```

#### Belirli Bir Profili Kurma
```bash
./install.sh web-development
./install.sh python-development
./install.sh minimal
```

#### Sadece Ayarları Kurma
```bash
./install.sh --settings-only web-development
```

#### Sadece Uzantıları Kurma
```bash
./install.sh --extensions-only python-development
```

#### Mevcut Ayarları Yedekleme
```bash
./install.sh --backup
```

#### Mevcut Profilleri Listeleme
```bash
./install.sh --list
```

## 📋 Kullanım

### Ana Kurulum Script'i

```bash
# Yardım menüsünü göster
./install.sh --help

# Mevcut profilleri listele
./install.sh --list

# Tam kurulum (ayarlar + uzantılar)
./install.sh web-development

# Sadece ayarları kur
./install.sh --settings-only python-development

# Sadece uzantıları kur
./install.sh --extensions-only minimal

# Mevcut ayarları yedekle
./install.sh --backup
```

### Bireysel Script'ler

#### Profil İçe Aktarma
```bash
# Yardım
./scripts/import-profile.sh --help

# Interaktif profil seçimi
./scripts/import-profile.sh

# Belirli profili içe aktar
./scripts/import-profile.sh web-development
```

#### Uzantı Yönetimi
```bash
# Yardım
./scripts/import-extensions.sh --help

# Mevcut uzantıları listele
./scripts/import-extensions.sh --list

# Profil uzantılarını kur
./scripts/import-extensions.sh python-development
```

## 🔧 Profil Oluşturma

Yeni bir profil oluşturmak için:

1. Yeni profil dizini oluşturun:
```bash
mkdir vscode/profiles/yeni-profil
```

2. Gerekli dosyaları oluşturun:
```bash
# settings.json - VSCode ayarları
touch vscode/profiles/yeni-profil/settings.json

# extensions.json - Yüklenecek uzantılar
touch vscode/profiles/yeni-profil/extensions.json

# keybindings.json - Klavye kısayolları (opsiyonel)
touch vscode/profiles/yeni-profil/keybindings.json
```

3. `vscode/profiles.json` dosyasını güncelleyin:
```json
{
    "profiles": [
        {
            "name": "yeni-profil",
            "description": "Yeni profil açıklaması",
            "category": "development"
        },
        // ... diğer profiller
    ]
}
```

## 📁 Dosya Formatları

### settings.json Örneği
```json
{
    "editor.fontSize": 14,
    "editor.tabSize": 2,
    "editor.formatOnSave": true,
    "workbench.colorTheme": "Default Dark+"
}
```

### extensions.json Örneği
```json
{
    "recommendations": [
        "ms-python.python",
        "ms-vscode.vscode-json",
        "eamodio.gitlens"
    ]
}
```

### keybindings.json Örneği
```json
[
    {
        "key": "ctrl+/",
        "command": "editor.action.commentLine",
        "when": "editorTextFocus && !editorReadonly"
    }
]
```

## 🔄 Yedekleme ve Geri Yükleme

### Otomatik Yedekleme
Her kurulum işlemi sırasında mevcut ayarlarınız otomatik olarak yedeklenir:
```bash
# Yedekleme dizini: ~/.vscode-backup-YYYYMMDD-HHMMSS
```

### Manuel Yedekleme
```bash
./install.sh --backup
```

### Geri Yükleme
Yedekleme dizinindeki dosyaları VSCode kullanıcı dizininize kopyalayın:
```bash
# Linux/macOS
cp ~/.vscode-backup-YYYYMMDD-HHMMSS/* ~/.config/Code/User/

# Windows
cp %APPDATA%\Code\User\* %APPDATA%\Code\User\
```

## 🐞 Sorun Giderme

### VSCode Bulunamadı
```bash
# VSCode'u PATH'e ekleyin
export PATH="$PATH:/usr/bin/code"

# veya VSCode'u yeniden kurun
```

### İzin Hataları
```bash
# Script'lere çalıştırma izni verin
chmod +x install.sh scripts/*.sh
```

### Profil Dosyaları Bulunamadı
```bash
# Doğru dizinde olduğunuzdan emin olun
pwd  # dotfiles dizini olmalı
ls vscode/profiles/  # profilleri kontrol et
```

## 🤝 Katkıda Bulunma

1. Bu repoyu fork'layın
2. Yeni bir özellik branch'i oluşturun (`git checkout -b feature/yeni-ozellik`)
3. Değişikliklerinizi commit'leyin (`git commit -am 'Yeni özellik eklendi'`)
4. Branch'inize push'layın (`git push origin feature/yeni-ozellik`)
5. Bir Pull Request oluşturun

## 📄 Lisans

Bu proje MIT lisansı altında dağıtılmaktadır. Daha fazla bilgi için [LICENSE](LICENSE) dosyasına bakın.

## 🙏 Teşekkürler

- VSCode ekibi için harika editör
- Topluluk katkıları için değerli uzantılar
- Tüm kullanıcılar için geri bildirimler

---

**İyi kodlamalar! 🚀**