#!/bin/bash

# VSCode Settings Sync Script
# Version: 2.0.0

# Script dizinini al
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# VSCode remote settings dizini
VSCODE_REMOTE_SETTINGS_DIR="$HOME/.vscode-remote/data/Machine"
VSCODE_REMOTE_SETTINGS_FILE="$VSCODE_REMOTE_SETTINGS_DIR/settings.json"
DOTFILES_SETTINGS_FILE="$DOTFILES_DIR/vscode/configs/settings.json"

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

# VSCode remote settings dizinini al
get_vscode_remote_settings_dir() {
    echo "$HOME/.vscode-remote/data/Machine"
}

# VSCode remote ayarlarını yedekle
backup_vscode_remote_settings() {
    local vscode_remote_settings_dir=$(get_vscode_remote_settings_dir)
    local backup_dir="$HOME/.vscode-remote-backup-$(date +%Y%m%d-%H%M%S)"
    
    if [[ -f "$vscode_remote_settings_dir/settings.json" ]]; then
        log_info "Mevcut VSCode remote ayarları yedekleniyor..."
        mkdir -p "$backup_dir"
        
        # Ayar dosyasını yedekle
        cp "$vscode_remote_settings_dir/settings.json" "$backup_dir/"
        
        log_success "Remote ayarlar yedeklendi: $backup_dir"
        echo "$backup_dir"
    else
        log_warning "VSCode remote settings dosyası bulunamadı, yedekleme atlanıyor."
        echo ""
    fi
}

# Banner göster
show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                  VSCode Settings Sync Script                ║"
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
    echo "  -r, --remove            Mevcut symlink'i kaldırır"
    echo "  -b, --backup            Mevcut ayarları yedekler"
    echo "  -s, --status            Sync durumunu gösterir"
    echo ""
    echo "Bu script, dotfiles'deki VSCode ayarlarını VSCode remote settings"
    echo "dosyasına symlink olarak bağlar."
}

# Mevcut ayarları yedekle
backup_settings() {
    if [[ -f "$VSCODE_REMOTE_SETTINGS_FILE" ]]; then
        local backup_dir=$(backup_vscode_remote_settings)
        if [[ -n "$backup_dir" ]]; then
            log_success "Ayarlar yedeklendi: $backup_dir/settings.json"
            echo "$backup_dir"
        fi
    else
        log_warning "Yedeklenecek ayar dosyası bulunamadı."
        echo ""
    fi
}

# Symlink oluştur
create_symlink() {
    log_step "VSCode Settings Symlink Oluşturuluyor..."
    echo ""
    
    # Dotfiles settings dosyasını kontrol et
    if [[ ! -f "$DOTFILES_SETTINGS_FILE" ]]; then
        log_error "Dotfiles settings dosyası bulunamadı: $DOTFILES_SETTINGS_FILE"
        return 1
    fi
    
    # VSCode remote settings dizinini oluştur
    if [[ ! -d "$VSCODE_REMOTE_SETTINGS_DIR" ]]; then
        log_info "VSCode remote settings dizini oluşturuluyor: $VSCODE_REMOTE_SETTINGS_DIR"
        mkdir -p "$VSCODE_REMOTE_SETTINGS_DIR"
    fi
    
    # Mevcut dosya varsa kaldır
    if [[ -f "$VSCODE_REMOTE_SETTINGS_FILE" ]]; then
        log_warning "Mevcut settings dosyası bulundu, yedekleniyor..."
        local backup_dir=$(backup_settings)
        if [[ -n "$backup_dir" ]]; then
            log_info "Yedekleme dizini: $backup_dir"
        fi
        
        log_info "Mevcut settings dosyası kaldırılıyor..."
        rm "$VSCODE_REMOTE_SETTINGS_FILE"
    fi
    
    # Symlink oluştur
    log_info "Symlink oluşturuluyor..."
    ln -s "$DOTFILES_SETTINGS_FILE" "$VSCODE_REMOTE_SETTINGS_FILE"
    
    if [[ $? -eq 0 ]]; then
        log_success "Symlink başarıyla oluşturuldu!"
        echo "  Kaynak: $DOTFILES_SETTINGS_FILE"
        echo "  Hedef:  $VSCODE_REMOTE_SETTINGS_FILE"
        return 0
    else
        log_error "Symlink oluşturulamadı!"
        return 1
    fi
}

# Symlink'i kaldır
remove_symlink() {
    log_step "VSCode Settings Symlink Kaldırılıyor..."
    echo ""
    
    if [[ -L "$VSCODE_REMOTE_SETTINGS_FILE" ]]; then
        log_info "Symlink kaldırılıyor: $VSCODE_REMOTE_SETTINGS_FILE"
        rm "$VSCODE_REMOTE_SETTINGS_FILE"
        log_success "Symlink başarıyla kaldırıldı."
    elif [[ -f "$VSCODE_REMOTE_SETTINGS_FILE" ]]; then
        log_warning "Symlink bulunamadı, ancak normal bir dosya mevcut."
        log_info "Dosyayı kaldırmak isterseniz manuel olarak silin: $VSCODE_REMOTE_SETTINGS_FILE"
    else
        log_info "Ayar dosyası bulunamadı."
    fi
}

# Durumu kontrol et
check_status() {
    log_step "VSCode Settings Durumu Kontrol Ediliyor..."
    echo ""
    
    if [[ -L "$VSCODE_REMOTE_SETTINGS_FILE" ]]; then
        local target=$(readlink "$VSCODE_REMOTE_SETTINGS_FILE")
        log_success "Symlink mevcut:"
        echo "  Kaynak: $target"
        echo "  Hedef:  $VSCODE_REMOTE_SETTINGS_FILE"
    elif [[ -f "$VSCODE_REMOTE_SETTINGS_FILE" ]]; then
        log_warning "Symlink bulunamadı, ancak normal bir dosya mevcut:"
        echo "  Dosya: $VSCODE_REMOTE_SETTINGS_FILE"
    else
        log_info "Ayar dosyası bulunamadı."
    fi
}

# Script'in çalıştığı dizini kontrol et
check_script_directory() {
    if [[ ! -f "vscode/configs/settings.json" ]]; then
        log_error "Bu script dotfiles dizininde çalıştırılmalı."
        log_info "Lütfen dotfiles dizinine gidin ve tekrar deneyin."
        exit 1
    fi
}

# Ana fonksiyon
main() {
    local mode="create"
    
    # Parametreleri kontrol et
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -r|--remove)
                mode="remove"
                shift
                ;;
            -b|--backup)
                mode="backup"
                shift
                ;;
            -s|--status)
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
    
    show_banner
    
    # Script dizinini kontrol et
    check_script_directory
    
    # Mode göre işlem yap
    case $mode in
        "create")
            create_symlink
            ;;
        "remove")
            remove_symlink
            ;;
        "backup")
            backup_settings
            ;;
        "status")
            check_status
            ;;
    esac
}

# Script'i çalıştır
main "$@"