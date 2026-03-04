#!/bin/bash
# 安全恢复脚本 - 使用GitHub令牌访问私有仓库

set -e

echo "=========================================="
echo "🔐 安全恢复系统"
echo "=========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 配置
GITHUB_USER="kiso0604"
REPO_NAME="openclaw-workspace"
WORKSPACE_DIR="/home/admin/openclaw/workspace"
ENCRYPTED_TOKEN_FILE=".github_token.enc"

# 获取GitHub令牌
get_github_token() {
    local token=""
    
    # 方法1：从加密文件获取
    if [ -f "$ENCRYPTED_TOKEN_FILE" ]; then
        echo "检测到加密令牌文件，请输入解密密码："
        read -s password
        token=$(openssl enc -aes-256-cbc -d -in "$ENCRYPTED_TOKEN_FILE" -pass pass:"$password" 2>/dev/null | grep "GITHUB_BACKUP_TOKEN=" | cut -d'=' -f2)
        
        if [ -n "$token" ]; then
            echo "✓ 从加密文件获取令牌成功"
            echo "$token"
            return 0
        else
            log_warn "解密失败或令牌无效"
        fi
    fi
    
    # 方法2：手动输入
    echo ""
    echo "请提供GitHub访问令牌："
    echo "1. 访问：https://github.com/settings/tokens"
    echo "2. 令牌需要 'repo' 权限"
    echo "3. 令牌格式：ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    echo ""
    read -s -p "请输入GitHub令牌: " token
    echo ""
    
    if [ -z "$token" ]; then
        log_error "未提供令牌"
        exit 1
    fi
    
    # 验证令牌格式
    if [[ ! "$token" =~ ^ghp_ ]]; then
        log_warn "令牌格式可能不正确，但继续尝试"
    fi
    
    echo "$token"
}

# 使用令牌克隆仓库
clone_with_token() {
    local token="$1"
    
    log_info "使用令牌访问私有仓库..."
    
    # 构建带令牌的URL
    REPO_URL="https://${GITHUB_USER}:${token}@github.com/${GITHUB_USER}/${REPO_NAME}.git"
    
    cd "$(dirname "$WORKSPACE_DIR")"
    
    # 备份现有数据
    if [ -d "$WORKSPACE_DIR" ]; then
        BACKUP_FILE="/tmp/openclaw-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
        log_info "备份现有数据: $BACKUP_FILE"
        tar -czf "$BACKUP_FILE" -C "$WORKSPACE_DIR" .
    fi
    
    # 克隆或更新仓库
    if [ -d "$WORKSPACE_DIR/.git" ]; then
        log_info "更新现有仓库..."
        cd "$WORKSPACE_DIR"
        
        # 更新远程URL
        git remote set-url origin "$REPO_URL"
        
        # 拉取最新更改
        if git pull origin main; then
            log_info "仓库更新成功"
        else
            log_warn "更新失败，尝试重新克隆..."
            cd ..
            rm -rf "$WORKSPACE_DIR"
            git clone "$REPO_URL" "$(basename "$WORKSPACE_DIR")"
        fi
    else
        log_info "克隆仓库..."
        rm -rf "$WORKSPACE_DIR"
        git clone "$REPO_URL" "$(basename "$WORKSPACE_DIR")"
    fi
    
    if [ $? -eq 0 ]; then
        log_info "✅ 仓库操作成功"
        return 0
    else
        log_error "❌ 仓库操作失败"
        return 1
    fi
}

# 验证恢复
verify_restore() {
    log_info "验证恢复结果..."
    
    cd "$WORKSPACE_DIR"
    
    local missing_files=()
    local required_files=("SOUL.md" "USER.md" "memory/" ".git")
    
    for file in "${required_files[@]}"; do
        if [ ! -e "$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -eq 0 ]; then
        log_info "✅ 所有关键文件存在"
        echo ""
        echo "恢复内容统计："
        echo "- 文件总数: $(find . -type f | wc -l)"
        echo "- 目录总数: $(find . -type d | wc -l)"
        echo "- 最新提交: $(git log --oneline -1 2>/dev/null || echo '无提交历史')"
        return 0
    else
        log_warn "以下文件缺失: ${missing_files[*]}"
        return 1
    fi
}

# 重启OpenClaw
restart_openclaw() {
    log_info "重启OpenClaw服务..."
    
    if command -v openclaw &> /dev/null; then
        if openclaw gateway restart; then
            log_info "✅ OpenClaw重启成功"
        else
            log_warn "⚠ OpenClaw重启失败，请手动重启"
        fi
    else
        log_error "❌ OpenClaw未安装"
    fi
}

# 创建恢复记录
create_restore_record() {
    cat > "$WORKSPACE_DIR/.restore_record.md" << EOF
# 恢复记录
- 恢复时间: $(date)
- 恢复方式: 安全令牌恢复
- GitHub用户: $GITHUB_USER
- 仓库: $REPO_NAME
- 恢复状态: $1
- 关键文件检查: $(if verify_restore >/dev/null; then echo "通过"; else echo "失败"; fi)
EOF
}

# 主函数
main() {
    echo "开始时间: $(date)"
    echo ""
    
    # 获取GitHub令牌
    local github_token
    github_token=$(get_github_token)
    if [ $? -ne 0 ] || [ -z "$github_token" ]; then
        log_error "无法获取有效的GitHub令牌"
        exit 1
    fi
    
    # 使用令牌恢复
    if clone_with_token "$github_token"; then
        log_info "✅ 数据恢复成功"
    else
        log_error "❌ 数据恢复失败"
        create_restore_record "失败"
        exit 1
    fi
    
    # 验证恢复
    if verify_restore; then
        log_info "✅ 恢复验证通过"
    else
        log_warn "⚠ 恢复验证有警告"
    fi
    
    # 重启服务
    restart_openclaw
    
    # 创建记录
    create_restore_record "成功"
    
    echo ""
    echo "=========================================="
    echo "✅ 安全恢复完成！"
    echo "=========================================="
    echo ""
    echo "📁 工作空间: $WORKSPACE_DIR"
    echo "🔐 恢复方式: GitHub令牌认证"
    echo "🕒 恢复时间: $(date)"
    echo ""
    echo "🚀 下一步："
    echo "1. 访问OpenClaw Web界面"
    echo "2. 善财应该能立即认出您"
    echo "3. 检查所有数据完整性"
    echo ""
    echo "💾 安全提示："
    echo "- 令牌已安全使用"
    echo "- 建议定期更换令牌"
    echo "- 保持加密令牌文件安全"
    echo "=========================================="
    
    echo ""
    echo "完成时间: $(date)"
}

# 执行主函数
main "$@"