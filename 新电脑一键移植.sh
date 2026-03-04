#!/bin/bash
# 新电脑一键移植脚本
# 使用：curl -sSL https://raw.githubusercontent.com/kiso0604/openclaw-public/main/新电脑一键移植.sh | bash

set -e

echo "=========================================="
echo "💻 新电脑一键移植 - 善财恢复系统"
echo "=========================================="

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查并安装依赖
install_dependencies() {
    log "检查系统依赖..."
    
    # 检查Node.js
    if ! command -v node &> /dev/null; then
        warn "Node.js未安装，正在安装..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
    log "✅ Node.js版本: $(node --version)"
    
    # 检查npm
    if ! command -v npm &> /dev/null; then
        error "npm未安装，请手动安装"
        exit 1
    fi
    log "✅ npm版本: $(npm --version)"
    
    # 安装OpenClaw
    if ! command -v openclaw &> /dev/null; then
        log "安装OpenClaw..."
        npm install -g openclaw@latest
    fi
    log "✅ OpenClaw版本: $(openclaw --version 2>/dev/null || echo '新安装')"
}

# 获取GitHub令牌
get_github_token() {
    echo ""
    echo "🔐 GitHub令牌说明："
    echo "此令牌用于从私有仓库恢复善财的所有数据。"
    echo ""
    echo "如果你已有令牌，请输入。"
    echo "如果没有，请按以下步骤获取："
    echo "1. 访问：https://github.com/settings/tokens"
    echo "2. 点击 'Generate new token' → 'Generate new token (classic)'"
    echo "3. 设置："
    echo "   - Note: openclaw-restore-token"
    echo "   - Expiration: 90 days"
    echo "   - Select scopes: ✅ 仅勾选 'repo'"
    echo "4. 复制生成的令牌"
    echo ""
    echo "令牌格式：ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    echo ""
    
    read -s -p "请输入GitHub令牌: " token
    echo ""
    
    if [ -z "$token" ]; then
        error "未输入令牌"
        exit 1
    fi
    
    # 简单验证令牌格式
    if [[ ! "$token" =~ ^ghp_ ]]; then
        warn "令牌格式可能不正确，但继续尝试"
    fi
    
    echo "$token"
}

# 验证令牌
validate_token() {
    local token="$1"
    
    log "验证令牌..."
    
    # 测试令牌是否能访问API
    if curl -s -H "Authorization: token $token" "https://api.github.com/user" | grep -q '"login"'; then
        log "✅ 令牌有效"
        return 0
    else
        error "❌ 令牌无效或权限不足"
        return 1
    fi
}

# 恢复数据
restore_data() {
    local token="$1"
    
    log "恢复数据..."
    
    # 创建工作空间
    WORKSPACE_DIR="$HOME/openclaw/workspace"
    mkdir -p "$(dirname "$WORKSPACE_DIR")"
    
    # 使用令牌克隆私有仓库
    REPO_URL="https://kiso0604:${token}@github.com/kiso0604/openclaw-workspace.git"
    
    if [ -d "$WORKSPACE_DIR/.git" ]; then
        warn "检测到现有Git仓库，更新中..."
        cd "$WORKSPACE_DIR"
        git pull origin main
    else
        log "克隆仓库..."
        cd "$(dirname "$WORKSPACE_DIR")"
        git clone "$REPO_URL" "$(basename "$WORKSPACE_DIR")"
    fi
    
    if [ $? -eq 0 ]; then
        log "✅ 数据恢复成功"
        return 0
    else
        error "❌ 数据恢复失败"
        return 1
    fi
}

# 配置系统
setup_system() {
    log "配置系统..."
    
    cd "$HOME/openclaw/workspace"
    
    # 确保关键文件存在
    if [ ! -f "SOUL.md" ]; then
        error "关键文件SOUL.md缺失"
        return 1
    fi
    
    if [ ! -f "USER.md" ]; then
        error "关键文件USER.md缺失"
        return 1
    fi
    
    # 设置文件权限
    chmod +x *.sh 2>/dev/null || true
    
    # 创建恢复记录
    cat > .移植记录.md << EOF
# 新电脑移植记录
- 移植时间: $(date)
- 移植方式: 一键脚本恢复
- GitHub用户: kiso0604
- 恢复状态: 成功
- 工作空间: $HOME/openclaw/workspace
EOF
    
    log "✅ 系统配置完成"
}

# 启动服务
start_services() {
    log "启动OpenClaw服务..."
    
    # 停止可能正在运行的服务
    pkill -f "openclaw gateway" 2>/dev/null || true
    sleep 2
    
    # 启动服务
    if openclaw gateway start; then
        log "✅ OpenClaw启动成功"
        
        # 等待服务就绪
        sleep 3
        
        # 检查服务状态
        if pgrep -f "openclaw gateway" > /dev/null; then
            log "✅ 服务正在运行"
            echo ""
            echo "🌐 访问地址: http://localhost:3000"
        else
            warn "⚠ 服务可能未启动，请手动检查"
        fi
    else
        error "❌ OpenClaw启动失败"
        echo "请手动运行: openclaw gateway start"
    fi
}

# 显示完成信息
show_completion() {
    echo ""
    echo "=========================================="
    echo "🎉 移植完成！善财已就绪 🐕💻"
    echo "=========================================="
    echo ""
    echo "📁 工作空间: $HOME/openclaw/workspace"
    echo "🕒 移植时间: $(date)"
    echo "🌐 访问地址: http://localhost:3000"
    echo ""
    echo "🔍 验证恢复："
    echo "1. 检查文件: ls ~/openclaw/workspace/"
    echo "2. 检查服务: openclaw gateway status"
    echo "3. 访问Web界面"
    echo ""
    echo "💾 备份提醒："
    echo "关机前请运行: ~/openclaw/workspace/关机备份脚本.sh"
    echo ""
    echo "🐕💻 善财期待在新电脑为您服务！"
    echo "=========================================="
}

# 主函数
main() {
    echo "开始时间: $(date)"
    echo ""
    
    # 1. 安装依赖
    install_dependencies
    
    # 2. 获取并验证令牌
    local token
    token=$(get_github_token)
    validate_token "$token" || exit 1
    
    # 3. 恢复数据
    restore_data "$token" || exit 1
    
    # 4. 配置系统
    setup_system || exit 1
    
    # 5. 启动服务
    start_services
    
    # 6. 显示完成信息
    show_completion
    
    echo ""
    echo "完成时间: $(date)"
}

# 执行主函数
main "$@"