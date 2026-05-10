#!/bin/bash

# Pyenv 環境互動式自動設定腳本
# 使用方法: ./setup_pyenv.sh

# 注意：不使用 set -e，因為腳本可能以 source 方式執行
# 若以 source 執行，set -e 會在遇到錯誤時關閉整個終端

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 輔助函數：印出彩色訊息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_prompt() {
    echo -e "${CYAN}[?]${NC} $1"
}

# 顯示主選單
show_main_menu() {
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}   Pyenv 環境管理工具${NC}"
    echo -e "${GREEN}================================${NC}"
    
    # 顯示 pyenv 狀態
    if command -v pyenv &> /dev/null; then
        local pyenv_version=$(pyenv --version 2>/dev/null | cut -d' ' -f2)
        echo -e "${BLUE}pyenv 版本: ${pyenv_version}${NC}"
        
        # 顯示當前環境
        local current_env=$(pyenv version-name 2>/dev/null || echo "系統預設")
        echo -e "${BLUE}當前環境: ${current_env}${NC}"
    fi
    
    echo ""
    echo "請選擇要執行的操作："
    echo ""
    echo "  1️⃣  建立新專案環境"
    echo "  2️⃣  查看已存在的虛擬環境"
    echo "  3️⃣  刪除虛擬環境"
    echo "  4️⃣  查看已安裝的 Python 版本"
    echo "  5️⃣  刪除 Python 版本"
    echo "  6️⃣  退出"
    echo ""
}

# 查看已存在的虛擬環境
show_existing_environments() {
    echo -e "${BLUE}========== 虛擬環境列表 ==========${NC}"
    echo ""
    
    print_info "pyenv 虛擬環境："
    local pyenv_envs=$(pyenv versions | grep -E "/envs/" | sed 's/^[ *]*//' | sed 's|.*/envs/||' | sort)
    
    if [ -n "$pyenv_envs" ]; then
        echo "$pyenv_envs" | while read -r env; do
            if [ -n "$env" ]; then
                # 檢查是否為當前使用的環境
                current_env=$(pyenv version-name 2>/dev/null)
                if [ "$env" = "$current_env" ]; then
                    echo "  ✅ $env (目前使用中)"
                else
                    echo "  📦 $env"
                fi
            fi
        done
    else
        echo "  (無 pyenv 虛擬環境)"
    fi
    
    echo ""
    print_info "搜尋專案內的 venv 目錄："
    
    # 搜尋常見的虛擬環境目錄
    local project_envs_found=false
    for dir in venv env .venv .env; do
        if find . -maxdepth 2 -type d -name "$dir" 2>/dev/null | head -5 | while read -r found_dir; do
            echo "  📁 $found_dir"
            project_envs_found=true
        done; then
            project_envs_found=true
        fi
    done
    
    if [ "$project_envs_found" = false ]; then
        echo "  (在當前目錄附近未找到 venv 相關目錄)"
    fi
    
    echo ""
}

# 刪除虛擬環境
delete_environment() {
    echo -e "${YELLOW}========== 刪除虛擬環境 ==========${NC}"
    echo ""
    
    # 顯示可刪除的環境
    print_info "可刪除的 pyenv 虛擬環境："
    local pyenv_envs=$(pyenv versions | grep -E "/envs/" | sed 's/^[ *]*//' | sed 's|.*/envs/||' | sort)
    
    if [ -z "$pyenv_envs" ]; then
        print_warning "沒有找到 pyenv 虛擬環境"
        return
    fi
    
    local count=1
    echo "$pyenv_envs" | while read -r env; do
        if [ -n "$env" ]; then
            echo "  $count. $env"
            count=$((count + 1))
        fi
    done
    
    echo ""
    local env_to_delete=$(get_user_input "請輸入要刪除的環境名稱")
    
    if [ -z "$env_to_delete" ]; then
        print_warning "操作已取消"
        return
    fi
    
    # 檢查環境是否存在
    if ! echo "$pyenv_envs" | grep -q "^$env_to_delete$"; then
        print_error "環境 '$env_to_delete' 不存在"
        return
    fi
    
    # 警告並確認
    print_warning "⚠️  即將刪除虛擬環境: $env_to_delete"
    print_warning "此操作無法復原！"
    
    if confirm_action "確定要刪除嗎？"; then
        print_info "刪除虛擬環境 '$env_to_delete'..."
        if pyenv uninstall -f "$env_to_delete"; then
            print_success "虛擬環境 '$env_to_delete' 已刪除"
        else
            print_error "刪除失敗"
        fi
    else
        print_info "操作已取消"
    fi
    
    echo ""
}

# 查看已安裝的 Python 版本
show_python_versions() {
    echo -e "${BLUE}========== Python 版本列表 ==========${NC}"
    echo ""
    
    print_info "已安裝的 Python 版本："
    local versions=$(pyenv versions --bare | grep -E "^[0-9]+\.[0-9]+\.[0-9]+$" | sort -V)
    
    if [ -n "$versions" ]; then
        echo "$versions" | while read -r version; do
            if [ -n "$version" ]; then
                # 檢查是否為當前使用的版本
                current_version=$(pyenv version-name 2>/dev/null)
                if [ "$version" = "$current_version" ]; then
                    echo "  ✅ Python $version (目前使用中)"
                else
                    echo "  🐍 Python $version"
                fi
                
                # 顯示該版本的虛擬環境
                local envs_for_version=$(pyenv versions | grep "$version/envs/" | sed 's/^[ *]*//' | sed 's|.*/envs/||' | head -3)
                if [ -n "$envs_for_version" ]; then
                    echo "$envs_for_version" | while read -r env; do
                        if [ -n "$env" ]; then
                            echo "     └── 📦 $env"
                        fi
                    done
                fi
            fi
        done
    else
        print_warning "沒有找到已安裝的 Python 版本"
        print_info "使用 'pyenv install <版本號>' 來安裝 Python"
    fi
    
    echo ""
    print_info "可安裝的最新版本參考："
    echo "  • Python 3.8.18, 3.9.18, 3.10.12"
    echo "  • Python 3.11.7, 3.12.1"
    echo ""
    print_info "查看所有可安裝版本: pyenv install --list"
    echo ""
}

# 刪除 Python 版本
delete_python_version() {
    echo -e "${YELLOW}========== 刪除 Python 版本 ==========${NC}"
    echo ""
    
    # 顯示可刪除的版本
    print_info "已安裝的 Python 版本："
    local versions=$(pyenv versions --bare | grep -E "^[0-9]+\.[0-9]+\.[0-9]+$" | sort -V)
    
    if [ -z "$versions" ]; then
        print_warning "沒有找到已安裝的 Python 版本"
        return
    fi
    
    local count=1
    echo "$versions" | while read -r version; do
        if [ -n "$version" ]; then
            # 檢查該版本是否有虛擬環境
            local env_count=$(pyenv versions | grep "$version/envs/" | wc -l)
            if [ "$env_count" -gt 0 ]; then
                echo "  $count. Python $version (⚠️  有 $env_count 個虛擬環境)"
            else
                echo "  $count. Python $version"
            fi
            count=$((count + 1))
        fi
    done
    
    echo ""
    local version_to_delete=$(get_user_input "請輸入要刪除的 Python 版本")
    
    if [ -z "$version_to_delete" ]; then
        print_warning "操作已取消"
        return
    fi
    
    # 檢查版本是否存在
    if ! echo "$versions" | grep -q "^$version_to_delete$"; then
        print_error "Python $version_to_delete 不存在"
        return
    fi
    
    # 檢查該版本是否有虛擬環境
    local dependent_envs=$(pyenv versions | grep "$version_to_delete/envs/" | sed 's/^[ *]*//' | sed 's|.*/envs/||')
    if [ -n "$dependent_envs" ]; then
        print_warning "⚠️  Python $version_to_delete 有以下虛擬環境："
        echo "$dependent_envs" | while read -r env; do
            if [ -n "$env" ]; then
                echo "     • $env"
            fi
        done
        print_warning "刪除 Python 版本會同時刪除所有相關的虛擬環境！"
        echo ""
    fi
    
    # 警告並確認
    print_warning "⚠️  即將刪除 Python $version_to_delete"
    print_warning "此操作無法復原！"
    
    if confirm_action "確定要刪除嗎？"; then
        print_info "刪除 Python $version_to_delete..."
        if pyenv uninstall -f "$version_to_delete"; then
            print_success "Python $version_to_delete 已刪除"
        else
            print_error "刪除失敗"
        fi
    else
        print_info "操作已取消"
    fi
    
    echo ""
}

# 安裝 pyenv
install_pyenv() {
    echo -e "${YELLOW}========== 安裝 pyenv ==========${NC}"
    echo ""
    
    print_info "準備安裝 pyenv..."
    print_warning "注意事項："
    echo "  • 安裝過程需要網路連線"
    echo "  • 可能需要 sudo 權限安裝依賴套件"
    echo "  • 安裝後需要重新啟動終端"
    echo ""
    
    if ! confirm_action "確定要安裝 pyenv 嗎？"; then
        print_warning "操作已取消"
        return 1
    fi
    
    echo ""
    print_info "開始安裝 pyenv..."
    
    # 檢查系統並安裝依賴套件
    print_info "檢查並安裝依賴套件..."
    
    if command -v apt &> /dev/null; then
        # Ubuntu/Debian 系統
        print_info "偵測到 Ubuntu/Debian 系統"
        print_warning "需要 sudo 權限安裝依賴套件"
        if confirm_action "是否要安裝編譯依賴套件？"; then
            sudo apt update
            sudo apt install -y make build-essential libssl-dev zlib1g-dev \
                libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
                libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev \
                liblzma-dev python3-openssl git
            print_success "依賴套件安裝完成"
        fi
    elif command -v yum &> /dev/null; then
        # CentOS/RHEL 系統
        print_info "偵測到 CentOS/RHEL 系統"
        print_warning "需要 sudo 權限安裝依賴套件"
        if confirm_action "是否要安裝編譯依賴套件？"; then
            sudo yum groupinstall -y "Development Tools"
            sudo yum install -y openssl-devel bzip2-devel libffi-devel
            print_success "依賴套件安裝完成"
        fi
    elif command -v brew &> /dev/null; then
        # macOS 系統
        print_info "偵測到 macOS 系統"
        print_info "請確保已安裝 Xcode Command Line Tools"
        if ! xcode-select -p &> /dev/null; then
            print_warning "未偵測到 Xcode Command Line Tools"
            if confirm_action "是否要安裝 Xcode Command Line Tools？"; then
                xcode-select --install
                print_info "請按照螢幕指示完成安裝，然後重新執行此腳本"
                return 1
            fi
        fi
    else
        print_warning "無法自動偵測系統類型，請手動安裝編譯依賴套件"
    fi
    
    echo ""
    
    # 下載並安裝 pyenv
    print_info "下載並安裝 pyenv..."
    if curl https://pyenv.run | bash; then
        print_success "pyenv 安裝完成"
    else
        print_error "pyenv 安裝失敗！"
        print_info "請檢查網路連線或手動安裝："
        echo "  curl https://pyenv.run | bash"
        return 1
    fi
    
    echo ""
    
    # 配置 shell 環境
    print_info "配置 shell 環境..."
    
    # 偵測當前使用的 shell
    current_shell=$(basename "$SHELL")
    case "$current_shell" in
        "bash")
            config_file="$HOME/.bashrc"
            ;;
        "zsh")
            config_file="$HOME/.zshrc"
            ;;
        *)
            config_file="$HOME/.profile"
            print_warning "未知的 shell: $current_shell，將使用 .profile"
            ;;
    esac
    
    print_info "將配置寫入: $config_file"
    
    # 檢查是否已經配置過
    if grep -q "pyenv init" "$config_file" 2>/dev/null; then
        print_info "pyenv 配置已存在於 $config_file"
    else
        print_info "添加 pyenv 配置到 $config_file..."
        
        # 備份現有配置檔
        if [ -f "$config_file" ]; then
            cp "$config_file" "$config_file.backup.$(date +%Y%m%d_%H%M%S)"
            print_info "已備份現有配置檔"
        fi
        
        # 添加 pyenv 配置
        cat >> "$config_file" << 'EOF'

# pyenv 配置
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
EOF
        
        print_success "pyenv 配置已添加到 $config_file"
    fi
    
    echo ""
    
    # 驗證安裝
    print_info "驗證安裝..."
    
    # 嘗試載入 pyenv
    export PATH="$HOME/.pyenv/bin:$PATH"
    if command -v pyenv &> /dev/null; then
        print_success "pyenv 安裝成功！"
        local pyenv_version=$(pyenv --version)
        print_info "版本: $pyenv_version"
    else
        print_warning "pyenv 可能安裝成功，但需要重新啟動終端"
    fi
    
    echo ""
    print_warning "重要：請執行以下其中一個動作來完成設定："
    echo ""
    echo "選項 1 - 重新載入配置檔："
    echo -e "  ${CYAN}source $config_file${NC}"
    echo ""
    echo "選項 2 - 重新啟動終端"
    echo ""
    echo "選項 3 - 手動執行（臨時生效）："
    echo -e "  ${CYAN}export PATH=\"\$HOME/.pyenv/bin:\$PATH\"${NC}"
    echo -e "  ${CYAN}eval \"\$(pyenv init -)\"${NC}"
    echo -e "  ${CYAN}eval \"\$(pyenv virtualenv-init -)\"${NC}"
    echo ""
    
    if confirm_action "是否要立即套用 pyenv 設定？"; then
        print_info "套用 pyenv 設定（不重新 source 整個配置檔，避免關閉終端）..."
        # 直接設定 PATH 與 pyenv 初始化，而非 source 整個 shell 配置檔
        # （source ~/.bashrc 等可能含有 exit 呼叫或其他副作用，會關閉終端）
        export PATH="$HOME/.pyenv/bin:$PATH"
        if command -v pyenv &>/dev/null; then
            eval "$(pyenv init -)" 2>/dev/null
            eval "$(pyenv virtualenv-init -)" 2>/dev/null
            print_success "pyenv 設定已套用"
            print_success "pyenv 現在可以使用了！"
            return 0
        else
            print_warning "pyenv 指令仍無法使用，請重新啟動終端後再試"
            return 1
        fi
    else
        print_info "請記得重新啟動終端或執行以下指令："
        echo -e "  ${CYAN}export PATH=\"\$HOME/.pyenv/bin:\$PATH\"${NC}"
        echo -e "  ${CYAN}eval \"\$(pyenv init -)\"${NC}"
        echo -e "  ${CYAN}eval \"\$(pyenv virtualenv-init -)\"${NC}"
        return 1
    fi
}

# 取得使用者輸入
get_user_input() {
    local prompt="$1"
    local default="$2"
    local user_input
    
    # 將提示輸出到 stderr，避免污染返回值
    if [ -n "$default" ]; then
        echo -n -e "${CYAN}$prompt [預設: $default]: ${NC}" >&2
    else
        echo -n -e "${CYAN}$prompt: ${NC}" >&2
    fi
    
    read -r user_input
    
    # 去除前後空格
    user_input=$(echo "$user_input" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    if [ -z "$user_input" ] && [ -n "$default" ]; then
        echo "$default"
    else
        echo "$user_input"
    fi
}

# 確認操作
confirm_action() {
    local message="$1"
    local response
    
    echo -n -e "${YELLOW}$message (y/N): ${NC}"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# 顯示已安裝的 Python 版本
show_available_versions() {
    echo ""
    print_info "檢查 pyenv 中已安裝的 Python 版本..."
    
    # 取得已安裝的版本
    local installed_versions
    installed_versions=$(pyenv versions --bare 2>/dev/null | grep -E "^[0-9]+\.[0-9]+\.[0-9]+$" | sort -V)
    
    if [ -n "$installed_versions" ]; then
        print_success "已安裝的 Python 版本："
        echo "$installed_versions" | while read -r version; do
            echo "  • $version"
        done
        echo ""
        print_info "你可以直接選擇上述任一版本"
    else
        print_warning "目前沒有已安裝的 Python 版本"
        print_info "常見的 Python 版本："
        echo "  • 3.8.18, 3.9.18, 3.10.12, 3.11.7, 3.12.1"
        echo ""
        print_info "如果選擇未安裝的版本，腳本會自動為你安裝"
    fi
    echo ""
}


# 偵測 pyproject.toml 的相依套件管理工具
get_pyproject_install_command() {
    local pyproject_file="${1:-pyproject.toml}"

    if [ ! -f "$pyproject_file" ]; then
        return 1
    fi

    # 優先使用專案宣告或鎖定檔對應的工具；若工具不存在，回退到 pip 安裝專案相依套件。
    if grep -Eq '^\[tool\.poetry(\.|\])' "$pyproject_file"; then
        if command -v poetry &> /dev/null; then
            echo "poetry install"
        else
            echo "pip install -e ."
        fi
    elif grep -Eq '^\[tool\.pdm(\.|\])' "$pyproject_file"; then
        if command -v pdm &> /dev/null; then
            echo "pdm install"
        else
            echo "pip install -e ."
        fi
    elif [ -f "uv.lock" ] && command -v uv &> /dev/null; then
        echo "uv pip install -e ."
    elif grep -Eq '^\[project\]|^dependencies[[:space:]]*=' "$pyproject_file"; then
        echo "pip install -e ."
    else
        return 1
    fi
}

# 偵測並安裝 TOML 專案相依套件
install_toml_dependencies() {
    local toml_files
    toml_files=$(find . -maxdepth 2 -type f -name "*.toml" \
        ! -path "*/$VENV_NAME/*" \
        ! -path "*/.venv/*" \
        ! -path "*/venv/*" \
        ! -path "*/env/*" 2>/dev/null | sort)

    if [ -z "$toml_files" ]; then
        return 0
    fi

    print_warning "發現專案內的 TOML 設定檔："
    echo "$toml_files" | while read -r toml_file; do
        if [ -n "$toml_file" ]; then
            echo "  • $toml_file"
        fi
    done

    if [ -f "pyproject.toml" ]; then
        local install_cmd
        if install_cmd=$(get_pyproject_install_command "pyproject.toml"); then
            print_info "偵測到 pyproject.toml，可用以下指令安裝專案相依套件："
            echo -e "  ${CYAN}$install_cmd${NC}"
            if confirm_action "是否要依據 pyproject.toml 安裝相依套件？"; then
                print_info "執行: $install_cmd"
                if eval "$install_cmd"; then
                    print_success "TOML 相依套件安裝完成"
                else
                    print_error "TOML 相依套件安裝失敗"
                    print_info "你可以稍後手動執行：$install_cmd"
                    return 1
                fi
            fi
        else
            print_warning "找到 pyproject.toml，但無法判斷可自動安裝的相依套件格式"
            print_info "支援格式：PEP 621 [project]、Poetry [tool.poetry]、PDM [tool.pdm]"
        fi
    else
        print_info "目前僅會自動安裝 pyproject.toml 宣告的 Python 相依套件"
    fi
}

# 驗證路徑
validate_path() {
    local path="$1"
    
    # 展開相對路徑
    if [[ "$path" == "." ]]; then
        path="$(pwd)"
    elif [[ "$path" == ".."* ]]; then
        path="$(cd "$path" && pwd)"
    elif [[ "$path" != "/"* ]]; then
        path="$(pwd)/$path"
    fi
    
    echo "$path"
}

# 主程序開始
main() {
    # 檢查 pyenv 是否已安裝
    if ! command -v pyenv &> /dev/null; then
        echo -e "${RED}========================================${NC}"
        echo -e "${RED}         未檢測到 pyenv${NC}"
        echo -e "${RED}========================================${NC}"
        echo ""
        
        print_warning "pyenv 未安裝！"
        print_info "pyenv 是 Python 版本管理工具，可以："
        echo "  • 管理多個 Python 版本"
        echo "  • 為每個專案設定獨立的 Python 版本"
        echo "  • 建立和管理虛擬環境"
        echo ""
        
        print_info "安裝選項："
        echo "  1. 讓此工具自動安裝 pyenv"
        echo "  2. 手動安裝 pyenv"
        echo "  3. 退出"
        echo ""
        
        local install_choice=""
        while true; do
            install_choice=$(get_user_input "請選擇 (1-3)" "1")
            
            case "$install_choice" in
                1)
                    print_info "將自動安裝 pyenv..."
                    if install_pyenv; then
                        print_success "pyenv 安裝完成！正在重新檢查..."
                        echo ""
                        
                        # 重新檢查 pyenv
                        if command -v pyenv &> /dev/null; then
                            print_success "pyenv 現在可以使用了！"
                            break
                        else
                            print_warning "pyenv 安裝完成，但需要重新啟動終端"
                            print_info "請重新啟動終端後再執行此腳本"
                            return 0
                        fi
                    else
                        print_error "pyenv 安裝失敗"
                        print_info "請嘗試手動安裝或重新啟動終端後再試"
                        return 1
                    fi
                    ;;
                2)
                    print_info "手動安裝 pyenv："
                    echo ""
                    echo "1. 安裝 pyenv："
                    echo -e "   ${CYAN}curl https://pyenv.run | bash${NC}"
                    echo ""
                    echo "2. 添加到 shell 配置檔 (~/.bashrc 或 ~/.zshrc)："
                    echo -e "   ${CYAN}export PATH=\"\$HOME/.pyenv/bin:\$PATH\"${NC}"
                    echo -e "   ${CYAN}eval \"\$(pyenv init -)\"${NC}"
                    echo -e "   ${CYAN}eval \"\$(pyenv virtualenv-init -)\"${NC}"
                    echo ""
                    echo "3. 重新啟動終端"
                    echo ""
                    print_info "完成後請重新執行此腳本"
                    return 0
                    ;;
                3)
                    print_success "再見！ 👋"
                    return 0
                    ;;
                *)
                    print_warning "請輸入 1-3 之間的數字，你輸入的是: '$install_choice'"
                    echo ""
                    ;;
            esac
        done
    fi
    
    # pyenv 已安裝，顯示主選單
    while true; do
        show_main_menu
        
        # 取得使用者選擇
        local choice=""
        while true; do
            choice=$(get_user_input "請選擇操作 (1-6)" "1")
            
            case "$choice" in
                1|2|3|4|5|6)
                    break
                    ;;
                *)
                    print_warning "請輸入 1-6 之間的數字，你輸入的是: '$choice'"
                    echo ""
                    ;;
            esac
        done
        
        echo ""
        
        # 執行對應的操作
        case "$choice" in
            1)
                create_new_project
                ;;
            2)
                show_existing_environments
                ;;
            3)
                delete_environment
                ;;
            4)
                show_python_versions
                ;;
            5)
                delete_python_version
                ;;
            6)
                print_success "再見！ 👋"
                return 0
                ;;
        esac
        
        # 詢問是否繼續
        echo ""
        if ! confirm_action "是否要繼續使用工具？"; then
            print_success "再見！ 👋"
            break
        fi
        
        echo ""
        echo "================================"
        echo ""
    done
}

# 建立新專案環境（原來的主要功能）
create_new_project() {
    echo -e "${GREEN}========== 建立新專案環境 ==========${NC}"
    echo ""
    
    # 重要提醒：關於 source 執行
    print_warning "重要提醒："
    echo "  如果你希望虛擬環境在腳本執行後仍然保持啟動狀態，"
    echo "  請使用以下方式執行此腳本："
    echo -e "  ${CYAN}source ./setup_pyenv.sh${NC}"
    echo "  或"
    echo -e "  ${CYAN}. ./setup_pyenv.sh${NC}"
    echo ""
    echo "  如果使用一般執行方式 (./setup_pyenv.sh)，"
    echo "  虛擬環境會在腳本結束後自動退出。"
    echo ""
    
    if ! confirm_action "了解上述說明，是否繼續？"; then
        print_info "你可以重新使用 'source ./setup_pyenv.sh' 執行"
        return
    fi
    echo ""
    
    # 1. 詢問專案路徑
    print_prompt "請輸入專案資料夾路徑"
    print_info "提示："
    echo "  • 使用 . 代表當前目錄"
    echo "  • 使用 ./my_project 建立子目錄"
    echo "  • 使用絕對路徑如 /home/user/project"
    echo ""
    
    PROJECT_PATH=$(get_user_input "專案路徑" ".")
    PROJECT_PATH=$(validate_path "$PROJECT_PATH")
    
    print_info "專案路徑設定為: $PROJECT_PATH"
    echo ""
    
    # 2. 詢問 Python 版本
    show_available_versions
    
    # 取得最新已安裝的版本作為預設值
    DEFAULT_VERSION="3.10.0"
    if command -v pyenv &> /dev/null; then
        LATEST_INSTALLED=$(pyenv versions --bare | grep -E "^[0-9]+\.[0-9]+\.[0-9]+$" | sort -V | tail -1)
        if [ -n "$LATEST_INSTALLED" ]; then
            DEFAULT_VERSION="$LATEST_INSTALLED"
            print_info "建議使用最新已安裝版本: $DEFAULT_VERSION"
            echo ""
        fi
    fi
    
    PYTHON_VERSION=$(get_user_input "請輸入 Python 版本" "$DEFAULT_VERSION")
    
    print_info "Python 版本設定為: $PYTHON_VERSION"
    echo ""
    
    # 3. 詢問虛擬環境建立方式
    print_prompt "請選擇虛擬環境建立方式"
    print_info "方式說明："
    echo "  1. pyenv virtualenv - 由 pyenv 統一管理，專案目錄保持乾淨"
    echo "  2. python -m venv - 建立在專案目錄內，專案自包含"
    echo ""
    print_info "建議："
    echo "  • 如果你經常使用 pyenv 管理多個 Python 版本 → 選擇 1"
    echo "  • 如果你希望專案完全自包含 → 選擇 2"
    echo ""
    
    VENV_METHOD=""
    while true; do
        VENV_METHOD=$(get_user_input "請選擇 (1/2)" "1")
        
        # 調試：顯示實際捕獲的值
        # print_info "調試：捕獲到的值是 '$VENV_METHOD'，長度是 ${#VENV_METHOD}"
        
        # 檢查輸入是否為 1 或 2
        if [[ "$VENV_METHOD" == "1" || "$VENV_METHOD" == "2" ]]; then
            break
        else
            print_warning "請輸入 1 或 2，你輸入的是: '$VENV_METHOD'"
            echo ""
        fi
    done
    
    if [ "$VENV_METHOD" = "1" ]; then
        print_info "已選擇: pyenv virtualenv 方式"
        # 檢查 pyenv-virtualenv 插件
        if ! pyenv virtualenv --help &> /dev/null; then
            print_error "pyenv-virtualenv 插件未安裝！"
            print_info "安裝方法："
            echo "  git clone https://github.com/pyenv/pyenv-virtualenv.git \$(pyenv root)/plugins/pyenv-virtualenv"
            echo "  然後重新啟動 shell 或執行: source ~/.bashrc"
            return 1
        fi
        
        print_prompt "請輸入虛擬環境名稱"
        print_info "建議格式: 專案名-python版本，例如 myproject-3.11"
        VENV_NAME=$(get_user_input "虛擬環境名稱" "$(basename "$PROJECT_PATH")-$(echo "$PYTHON_VERSION" | cut -d. -f1,2)")
        VENV_CREATE_CMD="pyenv virtualenv $PYTHON_VERSION $VENV_NAME"
        VENV_ACTIVATE_CMD="pyenv activate $VENV_NAME"
        VENV_LOCAL_CMD="pyenv local $VENV_NAME"
    else
        print_info "已選擇: python -m venv 方式"
        print_prompt "請輸入虛擬環境資料夾名稱"
        print_info "提示："
        echo "  • 常用名稱: venv, env, .venv"
        echo "  • 會建立在專案目錄內"
        VENV_NAME=$(get_user_input "虛擬環境資料夾名稱" "venv")
        VENV_CREATE_CMD="python -m venv $VENV_NAME"
        VENV_ACTIVATE_CMD="source $VENV_NAME/bin/activate"
        VENV_LOCAL_CMD=""
    fi
    
    print_info "虛擬環境設定為: $VENV_NAME"
    echo ""
    
    # 4. 確認設定
    echo -e "${YELLOW}========== 設定確認 ==========${NC}"
    echo "專案路徑: $PROJECT_PATH"
    echo "Python 版本: $PYTHON_VERSION"
    if [ "$VENV_METHOD" = "1" ]; then
        echo "虛擬環境方式: pyenv virtualenv"
        echo "虛擬環境名稱: $VENV_NAME"
        echo "建立位置: ~/.pyenv/versions/$VENV_NAME"
    else
        echo "虛擬環境方式: python -m venv"
        echo "虛擬環境名稱: $VENV_NAME"
        echo "建立位置: $PROJECT_PATH/$VENV_NAME"
    fi
    echo -e "${YELLOW}=============================${NC}"
    echo ""
    
    if ! confirm_action "確認開始設定環境？"; then
        print_warning "操作已取消"
        return 0
    fi
    
    echo ""
    print_info "開始設定環境..."
    
    # 4. 檢查並建立專案目錄
    if [ ! -d "$PROJECT_PATH" ]; then
        if confirm_action "目錄 $PROJECT_PATH 不存在，是否要建立？"; then
            mkdir -p "$PROJECT_PATH"
            print_success "已建立目錄: $PROJECT_PATH"
        else
            print_error "操作已取消"
            return 1
        fi
    fi

    # 5. 進入專案目錄
    print_info "進入專案目錄: $PROJECT_PATH"
    cd "$PROJECT_PATH" || {
        print_error "無法進入目錄: $PROJECT_PATH"
        return 1
    }
    
    # 6. 檢查並安裝 Python 版本
    print_info "檢查 Python $PYTHON_VERSION 是否已安裝..."
    if ! pyenv versions | grep -q "$PYTHON_VERSION"; then
        print_warning "Python $PYTHON_VERSION 未安裝"
        if confirm_action "是否要安裝 Python $PYTHON_VERSION？（這可能需要幾分鐘）"; then
            print_info "安裝 Python $PYTHON_VERSION..."
            print_info "提示：安裝過程可能需要 5-15 分鐘，請耐心等待..."
            
            # 強化錯誤處理的 pyenv install
            if ! pyenv install "$PYTHON_VERSION"; then
                print_error "Python $PYTHON_VERSION 安裝失敗！"
                print_info "可能的原因："
                echo "  • 網路連線問題"
                echo "  • 版本號不正確（請檢查 pyenv install --list）"
                echo "  • 系統缺少編譯依賴套件"
                echo ""
                print_info "建議解決方案："
                echo "  • 檢查網路連線"
                echo "  • 確認版本號正確性"
                echo "  • Ubuntu/Debian: sudo apt update && sudo apt install build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python-openssl git"
                echo "  • CentOS/RHEL: sudo yum groupinstall 'Development Tools' && sudo yum install openssl-devel bzip2-devel libffi-devel"
                echo "  • macOS: 確保已安裝 Xcode Command Line Tools"
                return 1
            fi
            print_success "Python $PYTHON_VERSION 安裝完成"
        else
            print_error "無法繼續，需要指定的 Python 版本"
            return 1
        fi
    else
        print_success "Python $PYTHON_VERSION 已安裝"
    fi
    
    # 7. 設定本地 Python 版本
    print_info "設定本地 Python 版本為 $PYTHON_VERSION"
    pyenv local "$PYTHON_VERSION"
    print_success "已設定本地 Python 版本: $PYTHON_VERSION"
    
    # 8. 處理虛擬環境
    if [ "$VENV_METHOD" = "1" ]; then
        # pyenv virtualenv 方式
        if pyenv versions | grep -q "$VENV_NAME"; then
            print_warning "pyenv 虛擬環境 '$VENV_NAME' 已存在"
            if confirm_action "是否要刪除重建？"; then
                print_info "刪除現有虛擬環境..."
                pyenv uninstall -f "$VENV_NAME"
                CREATE_VENV=true
            else
                print_info "將使用現有虛擬環境 '$VENV_NAME'"
                CREATE_VENV=false
            fi
        else
            CREATE_VENV=true
        fi
        
        # 9. 建立虛擬環境 (pyenv virtualenv)
        if [ "$CREATE_VENV" = true ]; then
            print_info "建立 pyenv 虛擬環境 '$VENV_NAME'..."
            if ! eval "$VENV_CREATE_CMD"; then
                print_error "pyenv 虛擬環境建立失敗！"
                print_info "可能的原因："
                echo "  • Python $PYTHON_VERSION 未正確安裝"
                echo "  • pyenv-virtualenv 插件問題"
                echo "  • 虛擬環境名稱衝突"
                return 1
            fi
            print_success "pyenv 虛擬環境 '$VENV_NAME' 建立完成"
        fi
        
        # 10. 設定專案使用此虛擬環境
        print_info "設定專案使用虛擬環境 '$VENV_NAME'..."
        
        # 檢查虛擬環境是否真的建立成功
        if ! pyenv versions | grep -q "$VENV_NAME"; then
            print_error "虛擬環境 '$VENV_NAME' 建立失敗或不存在！"
            print_info "請檢查："
            echo "  • pyenv versions 中是否有 $VENV_NAME"
            echo "  • pyenv-virtualenv 插件是否正常工作"
            return 1
        fi
        
        # 設定專案目錄使用此虛擬環境
        print_info "執行: pyenv local $VENV_NAME"
        if ! pyenv local "$VENV_NAME"; then
            print_error "設定專案虛擬環境失敗！"
            print_info "可能的原因："
            echo "  • 虛擬環境 '$VENV_NAME' 不存在"
            echo "  • pyenv-virtualenv 插件未正確配置"
            echo "  • 當前目錄權限問題"
            echo ""
            print_info "手動檢查："
            echo "  • pyenv versions  # 查看所有版本"
            echo "  • ls -la .python-version  # 檢查是否建立了配置檔"
            return 1
        fi
        
        # 驗證設定是否成功
        if [ -f ".python-version" ]; then
            local set_version=$(cat .python-version)
            if [ "$set_version" = "$VENV_NAME" ]; then
                print_success "已將專案設定為使用 '$VENV_NAME'"
                print_info "已建立 .python-version 檔案"
            else
                print_warning "設定可能有問題，.python-version 內容為: $set_version"
            fi
        else
            print_warning "未找到 .python-version 檔案，設定可能失敗"
        fi
        
        # 11. 啟動虛擬環境
        print_info "啟動 pyenv 虛擬環境 '$VENV_NAME'..."
        
        # 檢查 pyenv-virtualenv 是否正確配置
        shell_config_found=false
        for config_file in ~/.bashrc ~/.zshrc ~/.profile; do
            if [ -f "$config_file" ] && grep -q "pyenv virtualenv-init" "$config_file"; then
                shell_config_found=true
                break
            fi
        done
        
        if [ "$shell_config_found" = false ]; then
            print_warning "pyenv-virtualenv 可能未正確配置"
            print_info "要讓終端顯示虛擬環境名稱 (plant-3.11)，請確保以下內容已加入 shell 配置檔："
            echo '  export PATH="$HOME/.pyenv/bin:$PATH"'
            echo '  eval "$(pyenv init -)"'
            echo '  eval "$(pyenv virtualenv-init -)"  # ← 這行很重要！'
            echo ""
            print_info "然後執行: source ~/.bashrc 或 source ~/.zshrc"
            echo ""
        else
            print_success "pyenv-virtualenv 配置正確"
        fi
        
        # 嘗試啟動虛擬環境
        print_info "執行: pyenv activate $VENV_NAME"
        if pyenv activate "$VENV_NAME" 2>/dev/null; then
            print_success "pyenv 虛擬環境 '$VENV_NAME' 啟動成功"
            print_info "✨ 終端提示符前應該會顯示: ($VENV_NAME)"
        else
            print_warning "自動啟動失敗，但這是正常的"
            print_info "原因："
            echo "  • pyenv activate 在腳本中執行時效果有限"
            echo "  • 虛擬環境已設定，進入目錄時會自動啟動"
            echo ""
            print_info "驗證設定："
            echo "  • 重新進入目錄: cd . 或 cd $PROJECT_PATH"
            echo "  • 檢查當前版本: pyenv version"
            echo "  • 手動啟動: pyenv activate $VENV_NAME"
            echo "  • 終端應該顯示: ($VENV_NAME) 在提示符前"
        fi
        
        # 驗證當前 Python 環境
        print_info "驗證 Python 環境..."
        current_version=$(pyenv version-name 2>/dev/null || echo "未知")
        if [ "$current_version" = "$VENV_NAME" ]; then
            print_success "當前已使用虛擬環境: $current_version"
            print_info "🎉 終端提示符前應該顯示: ($current_version)"
        else
            print_info "當前版本: $current_version"
            print_info "設定的環境: $VENV_NAME"
            print_info "請執行 'cd .' 或重新進入目錄來啟動虛擬環境"
            print_info "成功後終端會顯示: ($VENV_NAME)"
        fi
        
    else
        # python -m venv 方式
        if [ -d "$VENV_NAME" ]; then
            print_warning "虛擬環境資料夾 '$VENV_NAME' 已存在"
            if confirm_action "是否要刪除重建？"; then
                print_info "刪除現有虛擬環境..."
                rm -rf "$VENV_NAME"
                CREATE_VENV=true
            else
                print_info "將使用現有虛擬環境 '$VENV_NAME'"
                CREATE_VENV=false
            fi
        else
            CREATE_VENV=true
        fi
        
        # 9. 建立虛擬環境 (python -m venv)
        if [ "$CREATE_VENV" = true ]; then
            print_info "建立虛擬環境 '$VENV_NAME'..."
            if ! $VENV_CREATE_CMD; then
                print_error "虛擬環境建立失敗！"
                print_info "可能的原因："
                echo "  • Python 版本不支援 venv 模組"
                echo "  • 磁碟空間不足"
                echo "  • 權限問題"
                return 1
            fi
            print_success "虛擬環境 '$VENV_NAME' 建立完成"
        fi
        
        # 10. 啟動虛擬環境
        print_info "啟動虛擬環境 '$VENV_NAME'..."
        
        # 強化錯誤處理的 source activate
        if [ ! -f "$VENV_NAME/bin/activate" ]; then
            print_error "虛擬環境啟動腳本不存在！"
            print_info "建議解決方案："
            echo "  • 重新建立虛擬環境: rm -rf $VENV_NAME && python -m venv $VENV_NAME"
            return 1
        fi
        
        # 嘗試啟動虛擬環境
        if ! eval "$VENV_ACTIVATE_CMD"; then
            print_error "虛擬環境啟動失敗！"
            print_info "建議解決方案："
            echo "  • 手動啟動: source $VENV_NAME/bin/activate"
            return 1
        fi
        
        # 驗證虛擬環境是否正確啟動
        if [[ "$VIRTUAL_ENV" != *"$VENV_NAME"* ]]; then
            print_warning "虛擬環境可能未正確啟動"
            print_info "這可能是因為使用 ./script.sh 而非 source script.sh 執行"
        else
            print_success "虛擬環境 '$VENV_NAME' 啟動成功"
        fi
    fi
    
    # 11. 升級 pip
    print_info "升級 pip..."
    pip install --upgrade pip > /dev/null 2>&1
    
    # 12. 處理 TOML 與 requirements.txt 相依套件
    install_toml_dependencies
    
    if [ -f "requirements.txt" ]; then
        print_warning "發現 requirements.txt 檔案"
        if confirm_action "是否要安裝相依套件？"; then
            print_info "安裝 requirements.txt 中的套件..."
            pip install -r requirements.txt
            print_success "套件安裝完成"
        fi
    fi
    
    # 13. 顯示完成訊息
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}         環境設定完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    print_info "當前環境資訊:"
    echo "  📁 專案路徑: $(pwd)"
    echo "  🐍 Python 版本: $(python --version)"
    if [ "$VENV_METHOD" = "1" ]; then
        echo "  📦 虛擬環境: $VENV_NAME (pyenv管理)"
        echo "  📍 環境位置: ~/.pyenv/versions/$VENV_NAME"
    else
        echo "  📦 虛擬環境: $VENV_NAME (專案內)"
        echo "  📍 環境位置: $(pwd)/$VENV_NAME"
    fi
    echo "  💾 pip 版本: $(pip --version | cut -d' ' -f2)"
    echo ""
    
    print_info "使用說明:"
    
    if [ "$VENV_METHOD" = "1" ]; then
        # pyenv virtualenv 方式的說明
        current_pyenv_version=$(pyenv version-name 2>/dev/null || echo "")
        if [ "$current_pyenv_version" = "$VENV_NAME" ]; then
            echo "  ✅ pyenv 虛擬環境已設定且目前啟動中"
            echo "  🚀 你現在可以直接開始開發"
            echo "  🔄 進入此目錄會自動啟動環境"
            echo "  🛑 退出環境: pyenv deactivate"
        else
            echo "  ⚠️  pyenv 虛擬環境已建立和設定，但可能未啟動"
            echo "  📁 配置檔: .python-version (內容: $(cat .python-version 2>/dev/null || echo '未找到'))"
            echo ""
            echo "  🔧 啟動方法："
            echo "     • 重新進入目錄: cd . && cd .."
            echo "     • 手動啟動: pyenv activate $VENV_NAME"
            echo "     • 檢查狀態: pyenv version"
            echo ""
            echo "  💡 如果自動啟動不工作，請檢查 shell 配置："
            echo "     在 ~/.bashrc 或 ~/.zshrc 中加入："
            echo "     eval \"\$(pyenv init -)\""
            echo "     eval \"\$(pyenv virtualenv-init -)\""
            echo ""
            echo "  🛑 退出環境: pyenv deactivate"
        fi
        echo "  📋 查看 pyenv 環境: pyenv versions"
        echo "  🗑️  刪除環境: pyenv uninstall $VENV_NAME"
    else
        # python -m venv 方式的說明
        if [[ "$VIRTUAL_ENV" == *"$VENV_NAME"* ]]; then
            echo "  ✅ 虛擬環境已啟動且持久生效"
            echo "  🚀 你現在可以直接開始開發"
            echo "  🛑 退出虛擬環境: deactivate"
        else
            echo "  ⚠️  虛擬環境未持久啟動"
            echo "  🔄 下次請使用: ${CYAN}source ./setup_pyenv.sh${NC} 執行"
            echo "  🚀 手動啟動: cd $PROJECT_PATH && source $VENV_NAME/bin/activate"
            echo "  🛑 退出虛擬環境: deactivate"
        fi
        echo "  🗑️  刪除環境: rm -rf $VENV_NAME"
    fi
    
    echo "  📋 查看已安裝套件: pip list"
    echo "  📦 安裝新套件: pip install <套件名>"
    echo "  💾 匯出套件清單: pip freeze > requirements.txt"
    echo ""
    
    print_success "祝你開發愉快！ 🎉"
}

# 執行主程序
main