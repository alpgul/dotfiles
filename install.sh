#!/bin/bash

# Dotfiles VSCode Profile Manager - Main Installation Script
# Version: 2.0.0

# Script dizinini al
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Renkler için tanımlamalar
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Log fonksiyonları
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# Script'in çalıştığı dizini kontrol et
check_script_directory() {
    if [[ ! -f "vscode/configs/settings.json" ]]; then
        log_error "Bu script dotfiles dizininde çalıştırılmalı."
        log_info "Lütfen dotfiles dizinine gidin ve tekrar deneyin."
        exit 1
    fi
}

# Banner göster
show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    VSCode Dotfiles Manager                  ║"
    echo "║                         Version 2.0.0                       ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Kullanım bilgisi
show_usage() {
    echo "Kullanım: $0 [seçenek]"
    echo ""
    echo "Seçenekler:"
    echo "  -h, --help              Bu yardım mesajını gösterir"
    echo "  -s, --sync              VSCode settings sync kurulumu yapar"
    echo "  -r, --remove            Sync symlink'ini kaldırır"
    echo "  -b, --backup            Mevcut ayarları yedekler"
    echo "  --status                Sync durumunu gösterir"
    echo ""
    echo "Bu script, VSCode settings sync için symlink kurulumu yapar."
    echo "vscode/configs/settings.json dosyasını ~/.vscode-remote/data/Machine/settings.json"
    echo "dosyasına symlink olarak bağlar."
    echo ""
    echo "Örnekler:"
    echo "  $0                      VSCode settings sync kurulumu yapar"
    echo "  $0 -s                   VSCode settings sync kurulumu yapar"
    echo "  $0 -r                   Sync symlink'ini kaldırır"
    echo "  $0 --status             Sync durumunu gösterir"
}

# VSCode settings sync kurulumu
sync_settings() {
    show_banner
    log_step "VSCode Settings Sync Kurulumu"
    echo ""
    
    # Sync scriptini çalıştır
    if [[ -f "$SCRIPT_DIR/scripts/set-vscode-settings.sh" ]]; then
        "$SCRIPT_DIR/scripts/set-vscode-settings.sh"
    else
        log_error "Sync scripti bulunamadı: $SCRIPT_DIR/scripts/set-vscode-settings.sh"
        exit 1
    fi
}

# Sync symlink'ini kaldır
remove_sync() {
    show_banner
    log_step "VSCode Settings Sync Kaldırma"
    echo ""
    
    # Sync scriptini çalıştır
    if [[ -f "$SCRIPT_DIR/scripts/set-vscode-settings.sh" ]]; then
        "$SCRIPT_DIR/scripts/set-vscode-settings.sh" --remove
    else
        log_error "Sync scripti bulunamadı: $SCRIPT_DIR/scripts/set-vscode-settings.sh"
        exit 1
    fi
}

# Sync durumunu göster
show_sync_status() {
    show_banner
    log_step "VSCode Settings Sync Durumu"
    echo ""
    
    # Sync scriptini çalıştır
    if [[ -f "$SCRIPT_DIR/scripts/set-vscode-settings.sh" ]]; then
        "$SCRIPT_DIR/scripts/set-vscode-settings.sh" --status
    else
        log_error "Sync scripti bulunamadı: $SCRIPT_DIR/scripts/set-vscode-settings.sh"
        exit 1
    fi
}

# Mevcut ayarları yedekle
backup_settings() {
    show_banner
    log_step "VSCode Ayarları Yedekleniyor..."
    echo ""
    
    # VSCode kurulumunu kontrol et
    if ! check_vscode_installation; then
        log_error "VSCode kurulu değil veya PATH'de bulunamadı."
        exit 1
    fi
    
    local backup_dir=$(backup_vscode_settings)
    if [[ -n "$backup_dir" ]]; then
        log_success "Ayarlar başarıyla yedeklendi: $backup_dir"
    else
        log_warning "Yedeklenecek ayar bulunamadı."
    fi
}

# Tam kurulum (ayarlar + uzantılar)
full_installation() {
    local profile_name="$1"
    
    show_banner
    log_step "VSCode Profil Tam Kurulumu"
    echo ""
    
    # VSCode kurulumunu kontrol et
    if ! check_vscode_installation; then
        log_error "VSCode kurulu değil veya PATH'de bulunamadı."
        log_info "Lütfen VSCode'u kurun ve tekrar deneyin."
        exit 1
    fi
    
    log_success "VSCode kurulumu bulundu."
    
    # Profil seçimi
    if [[ -z "$profile_name" ]]; then
        profile_name=$(select_profile)
    else
        # Profil geçerliliğini kontrol et
        if ! validate_profile "$profile_name"; then
            log_error "Geçersiz profil: $profile_name"
            log_info "Mevcut profilleri görmek için: $0 --help"
            exit 1
        fi
    fi
    
    echo ""
    log_info "Seçilen profil: $profile_name"
    echo ""
    
    # Mevcut ayarları yedekle
    local backup_dir=$(backup_vscode_settings)
    if [[ -n "$backup_dir" ]]; then
        log_info "Yedekleme dizini: $backup_dir"
    fi
    
    echo ""
    
    # Profil ayarlarını kopyala
    if copy_profile_settings "$profile_name"; then
        log_success "Profil ayarları başarıyla içe aktarıldı."
    else
        log_error "Profil ayarları içe aktarılamadı."
        exit 1
    fi
    
    echo ""
    
    # Uzantıları yükle
    log_step "Profil uzantıları yükleniyor..."
    local extensions=$(get_extensions_from_profile "$profile_name")
    
    if [[ -n "$extensions" ]]; then
        while IFS= read -r extension; do
            if [[ -n "$extension" ]]; then
                log_info "Uzantı yükleniyor: $extension"
                if code --install-extension "$extension" --force &> /dev/null; then
                    log_success "Uzantı başarıyla yüklendi: $extension"
                else
                    log_error "Uzantı yüklenemedi: $extension"
                fi
            fi
        done <<< "$extensions"
        
        log_success "Uzantı yükleme işlemi tamamlandı."
    else
        log_warning "Profil için uzantı bulunamadı: $profile_name"
    fi
    
    echo ""
    log_step "Kurulum tamamlandı!"
    log_info "VSCode'u yeniden başlatmanız önerilir."
    
    if [[ -n "$backup_dir" ]]; then
        log_info "Eğer eski ayarlara geri dönmek isterseniz, yedekleme dizinini kullanabilirsiniz:"
        echo "  $backup_dir"
    fi
}

# Sadece ayarları kur
settings_only_installation() {
    local profile_name="$1"
    
    show_banner
    log_step "VSCode Profil Ayarları Kurulumu"
    echo ""
    
    # VSCode kurulumunu kontrol et
    if ! check_vscode_installation; then
        log_error "VSCode kurulu değil veya PATH'de bulunamadı."
        exit 1
    fi
    
    # Profil seçimi
    if [[ -z "$profile_name" ]]; then
        profile_name=$(select_profile)
    else
        if ! validate_profile "$profile_name"; then
            log_error "Geçersiz profil: $profile_name"
            exit 1
        fi
    fi
    
    echo ""
    log_info "Seçilen profil: $profile_name"
    echo ""
    
    # Mevcut ayarları yedekle
    local backup_dir=$(backup_vscode_settings)
    if [[ -n "$backup_dir" ]]; then
        log_info "Yedekleme dizini: $backup_dir"
    fi
    
    echo ""
    
    # Profil ayarlarını kopyala
    if copy_profile_settings "$profile_name"; then
        log_success "Profil ayarları başarıyla içe aktarıldı."
    else
        log_error "Profil ayarları içe aktarılamadı."
        exit 1
    fi
    
    echo ""
    log_step "Ayarlar kurulumu tamamlandı!"
    log_info "VSCode'u yeniden başlatmanız önerilir."
}

# Sadece uzantıları kur
extensions_only_installation() {
    local profile_name="$1"
    
    show_banner
    log_step "VSCode Profil Uzantıları Kurulumu"
    echo ""
    
    # VSCode kurulumunu kontrol et
    if ! check_vscode_installation; then
        log_error "VSCode kurulu değil veya PATH'de bulunamadı."
        exit 1
    fi
    
    # Profil seçimi
    if [[ -z "$profile_name" ]]; then
        profile_name=$(select_profile)
    else
        if ! validate_profile "$profile_name"; then
            log_error "Geçersiz profil: $profile_name"
            exit 1
        fi
    fi
    
    echo ""
    log_info "Seçilen profil: $profile_name"
    echo ""
    
    # Uzantıları yükle
    local extensions=$(get_extensions_from_profile "$profile_name")
    
    if [[ -n "$extensions" ]]; then
        while IFS= read -r extension; do
            if [[ -n "$extension" ]]; then
                log_info "Uzantı yükleniyor: $extension"
                if code --install-extension "$extension" --force &> /dev/null; then
                    log_success "Uzantı başarıyla yüklendi: $extension"
                else
                    log_error "Uzantı yüklenemedi: $extension"
                fi
            fi
        done <<< "$extensions"
        
        echo ""
        log_success "Uzantı yükleme işlemi tamamlandı."
        log_info "VSCode'u yeniden başlatmanız önerilir."
    else
        log_warning "Profil için uzantı bulunamadı: $profile_name"
    fi
}

# Ana fonksiyon
main() {
    local mode="sync"
    
    # Parametreleri kontrol et
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -s|--sync)
                mode="sync"
                shift
                ;;
            -r|--remove)
                mode="remove"
                shift
                ;;
            -b|--backup)
                mode="backup"
                shift
                ;;
            --status)
                mode="status"
                shift
                ;;
            -*)
                log_error "Bilinmeyen seçenek: $1"
                show_usage
                exit 1
                ;;
            *)
                log_error "Beklenmeyen parametre: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Script dizinini kontrol et
    check_script_directory
    
    # Mod göre işlem yap
    case $mode in
        "sync")
            sync_settings
            ;;
        "remove")
            remove_sync
            ;;
        "backup")
            if [[ -f "$SCRIPT_DIR/scripts/set-vscode-settings.sh" ]]; then
                "$SCRIPT_DIR/scripts/set-vscode-settings.sh" --backup
            else
                log_error "Sync scripti bulunamadı: $SCRIPT_DIR/scripts/set-vscode-settings.sh"
                exit 1
            fi
            ;;
        "status")
            show_sync_status
            ;;
    esac
}

# Script'i çalıştır
main "$@"