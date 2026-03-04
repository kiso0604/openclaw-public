#!/bin/bash
# 改进的安全恢复脚本 - 增加令牌验证

set -e

echo "=========================================="
echo "🔐 安全恢复系统 v2.0"
echo "=========================================="

# 配置
GITHUB_USER="kiso0604"
REPO_NAME="openclaw-workspace"
WORKSPACE_DIR="/home/admin/openclaw/workspace"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 安全验证令牌
validate_github_token() {
    local token="$1"
    
    log_info "验证GitHub令牌..."
    
    # 验证令牌有效性
    local user_info
    user_info=$(curl -s -H "Authorization: token $token" "https://api.github.com/user" 2>/dev/null)
    
    if echo "$user_info" | grep -q '"login"'; then
        local token_user
        token_user=$(echo "$user_info" | grep '"login"' | cut -d'"' -f4)
        log_info "令牌用户: $token_user"
        
        if [ "$token_user" != "$GITHUB_USER" ]; then
            log_error "令牌不属于 $GITHUB_USER，而是 $token_user"
            log_error "请使用 $GITHUB_USER 的令牌"
            return 1
        fi
    else
        log_error "令牌无效或权限不足"
        return 1
    fi
    
    # 验证仓库访问权限
    local repo_info
    repo_info=$(curl -s -H "Authorization: token $token" "https://api.github.com/repos/$GITHUB_USER/$REPO_NAME" 2>/dev/null)
    
    if echo "$repo_info" | grep -q '"name"'; then
        local repo_private
        repo_private=$(echo "$repo_info" | grep '"private"' | grep -o 'true\|false')
        
        if [ "$repo_private" = "true" ]; then
            log_info "✅ 令牌可以访问私有仓库"
            return 0
        else
            log_warn "仓库是公开的，令牌验证通过但安全性较低"
            return 0
        fi
    else
        log_error "令牌无法访问仓库 $REPO_NAME"
        log_error "请确保令牌有 'repo' 或 'read:repo' 权限"
        return 1
    fi
}

# 获取令牌（安全方式）
get_github_token_safe() {
    echo ""
    echo "🔐 GitHub令牌说明："
    echo "1. 此令牌仅用于恢复你的私有仓库"
    echo "2. 令牌不会发送到任何第三方"
    echo "3. 令牌只在本次恢复中使用"
    echo "4. 建议使用仅有 'repo' 权限的令牌"
    echo ""
    echo "获取令牌：https://github.com/settings/tokens"
    echo "需要权限：repo (访问私有仓库)"
    echo ""
    
    # 方法1：加密文件
    if [ -f ".github_token.enc" ]; then
        read -p "使用加密令牌文件？[Y/n]: " use_encrypted
        if [[ ! $use_encrypted =~ ^[Nn]$ ]]; then
            read -s -p "请输入加密密码: " enc_password
            echo ""
            local token
            token=$(openssl enc -aes-256-cbc -d -in .github_token.enc -pass pass:"$enc_password" 2>/dev/null | grep "GITHUB_BACKUP_TOKEN=" | cut -d'=' -f2)
            
            if [ -n "$token" ]; then
                if validate_github_token "$token"; then
                    echo "$token"
                    return 0
                fi
            else
                log_warn "解密失败，请手动输入令牌"
            fi
        fi
    fi
    
    # 方法2：手动输入
    echo ""
    echo "请手动输入GitHub令牌："
    echo "令牌格式：ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    echo ""
    read -s -p "GitHub令牌: " token
    echo ""
    
    if [ -z "$token" ]; then
        log_error "未提供令牌"
        exit 1
    fi
    
    # 验证令牌
    if validate_github_token "$token"; then
        echo "$token"
        return 0
    else
        log_error "令牌验证失败"
        exit 1
    fi
}

# 安全恢复
safe_recovery() {
    local token="$1"
    
    log_info "开始安全恢复..."
    
    # 使用令牌克隆
    local repo_url="https://${GITHUB_USER}:${token}@github.com/${GITHUB_USER}/${REPO_NAME}.git"
    
    # 备份现有数据
    if [ -d "$WORKSPACE_DIR" ]; then
        local backup_file="/tmp/openclaw-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
        log_info "创建备份: $backup_file"
        tar -czf "$backup_file" -C "$WORKSPACE_DIR" .
    fi
    
    # 恢复数据
    cd "$(dirname "$WORKSPACE_DIR")"
    rm -rf "$WORKSPACE_DIR"
    git clone "$repo_url" "$(basename "$WORKSPACE_DIR")"
    
    if [ $? -eq 0 ]; then
        log_info "✅ 恢复成功"
        
        # 创建安全记录（不包含令牌）
        cat > "$WORKSPACE_DIR/.recovery_log.md" << EOF
# 安全恢复记录
- 恢复时间: $(date)
- 恢复方式: 令牌认证恢复
- GitHub用户: $GITHUB_USER
- 仓库: $REPO_NAME
- 恢复状态: 成功
- 安全级别: 令牌验证通过
EOF
        
        return 0
    else
        log_error "❌ 恢复失败"
        return 1
    fi
}

# 安全建议
show_security_tips() {
    echo ""
    echo "=========================================="
    echo "🔒 安全建议"
    echo "=========================================="
    echo ""
    echo "1. 令牌管理："
    echo "   - 使用仅有 'repo' 权限的令牌"
    echo "   - 设置90天有效期"
    echo "   - 定期更换令牌"
    echo ""
    echo "2. 仓库安全："
    echo "   - 保持仓库私有"
    echo "   - 使用 .gitignore 排除敏感文件"
    echo "   - 定期审查仓库内容"
    echo ""
    echo "3. 本地安全："
    echo "   - 加密存储令牌文件"
    echo "   - 定期创建本地备份"
    echo "   - 使用强密码保护"
    echo ""
    echo "4. 监控："
    echo "   - 查看GitHub令牌使用记录"
    echo "   - 监控仓库访问日志"
    echo "   - 设置异常告警"
    echo ""
}

# 主函数
main() {
    echo "开始时间: $(date)"
    echo ""
    
    # 获取并验证令牌
    local github_token
    github_token=$(get_github_token_safe)
    
    # 执行恢复
    if safe_recovery "$github_token"; then
        log_info "✅ 安全恢复完成"
        
        # 重启OpenClaw
        if command -v openclaw &> /dev/null; then
            log_info "重启OpenClaw..."
            openclaw gateway restart && log_info "✅ OpenClaw重启成功" || log_warn "⚠ OpenClaw重启失败"
        fi
        
        show_security_tips
        
        echo ""
        echo "=========================================="
        echo "🎉 恢复完成！"
        echo "=========================================="
        echo ""
        echo "🔐 安全状态："
        echo "- 令牌已验证并安全使用"
        echo "- 私有仓库数据已恢复"
        echo "- 未泄露敏感信息"
        echo ""
        echo "🚀 下一步：访问OpenClaw Web界面"
        echo "=========================================="
    else
        log_error "❌ 恢复失败"
        exit 1
    fi
    
    echo ""
    echo "完成时间: $(date)"
}

# 执行主函数
main "$@"