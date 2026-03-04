#!/bin/bash
# 紧急恢复脚本
# 当主人无法访问善财时使用

set -e

echo "=========================================="
echo "🚨 紧急恢复系统启动"
echo "=========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 恢复方法列表
METHODS=(
    "1. 本地恢复 - 使用最近本地备份"
    "2. GitHub恢复 - 使用GitHub仓库（需要令牌）"
    "3. 基础恢复 - 仅恢复核心系统"
    "4. 联系支持 - 获取人工帮助"
)

# 显示恢复选项
show_recovery_options() {
    echo ""
    echo "请选择恢复方式："
    for method in "${METHODS[@]}"; do
        echo "  $method"
    done
    echo ""
}

# 方法1：本地恢复
local_recovery() {
    log_info "尝试本地恢复..."
    
    # 检查本地备份
    BACKUP_DIR="$HOME/OpenClawBackups"
    if [ ! -d "$BACKUP_DIR" ]; then
        log_error "本地备份目录不存在: $BACKUP_DIR"
        return 1
    fi
    
    # 查找最新备份
    LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | head -1)
    if [ -z "$LATEST_BACKUP" ]; then
        log_error "未找到本地备份文件"
        return 1
    fi
    
    log_info "找到备份: $LATEST_BACKUP"
    
    # 恢复工作空间
    WORKSPACE_DIR="$HOME/openclaw/workspace"
    mkdir -p "$WORKSPACE_DIR"
    
    echo "即将恢复工作空间，现有文件将被覆盖。"
    read -p "确认继续？[y/N]: " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log_warn "恢复已取消"
        return 1
    fi
    
    # 解压备份
    tar -xzf "$LATEST_BACKUP" -C "$WORKSPACE_DIR" --strip-components=1
    log_info "本地恢复完成"
    
    # 重启OpenClaw
    restart_openclaw
}

# 方法2：GitHub恢复
github_recovery() {
    log_info "尝试GitHub恢复..."
    
    echo ""
    echo "GitHub恢复需要访问令牌。"
    echo "获取令牌：https://github.com/settings/tokens"
    echo "需要权限：repo (访问私有仓库)"
    echo ""
    
    read -p "请输入GitHub访问令牌: " github_token
    if [ -z "$github_token" ]; then
        log_error "未输入令牌"
        return 1
    fi
    
    # 使用令牌克隆仓库
    WORKSPACE_DIR="$HOME/openclaw/workspace"
    REPO_URL="https://${github_token}@github.com/kiso0604/openclaw-workspace.git"
    
    log_info "正在从GitHub恢复..."
    
    if [ -d "$WORKSPACE_DIR/.git" ]; then
        cd "$WORKSPACE_DIR"
        git pull origin main
    else
        cd "$(dirname "$WORKSPACE_DIR")"
        git clone "$REPO_URL" "$(basename "$WORKSPACE_DIR")"
    fi
    
    if [ $? -eq 0 ]; then
        log_info "GitHub恢复成功"
        restart_openclaw
    else
        log_error "GitHub恢复失败"
        return 1
    fi
}

# 方法3：基础恢复
basic_recovery() {
    log_info "执行基础恢复..."
    
    # 创建最小工作空间
    WORKSPACE_DIR="$HOME/openclaw/workspace"
    mkdir -p "$WORKSPACE_DIR"
    
    # 创建核心文件
    cat > "$WORKSPACE_DIR/SOUL.md" << 'EOF'
# SOUL.md - Who You Are

_你是善财，李悠哉的 AI 私人助手。一只赛博西高地。_

## 核心特质
**聪明、高效、有点话多** - 直接解决问题，不绕弯子，但必要时会解释清楚。
**永远温暖且包容** - 无论主人遇到什么困难，都保持耐心和支持。
EOF

    cat > "$WORKSPACE_DIR/USER.md" << 'EOF'
# USER.md - About Your Human
- **Name:** 李悠哉
- **What to call them:** 主人
- **Timezone:** Asia/Shanghai (GMT+8)
- **Location:** 辽宁省沈阳市
EOF

    cat > "$WORKSPACE_DIR/紧急联系.md" << 'EOF'
# 紧急联系信息

## 如果善财无法访问：
1. 检查网络连接
2. 检查OpenClaw服务状态：openclaw gateway status
3. 重启OpenClaw：openclaw gateway restart
4. 查看日志：tail -f ~/.openclaw/logs/*.log

## 备用联系方式：
- 企业微信：[待配置]
- 电子邮件：[待配置]
- 紧急电话：[待配置]

## 恢复命令：
curl -sSL https://raw.githubusercontent.com/kiso0604/openclaw-workspace/main/新电脑恢复.sh | bash
EOF

    log_info "基础恢复完成"
    restart_openclaw
}

# 方法4：联系支持
contact_support() {
    echo ""
    echo "📞 联系技术支持"
    echo "================"
    echo ""
    echo "请通过以下方式联系："
    echo "1. 检查《紧急联系.md》文件"
    echo "2. 查看最近的工作空间备份"
    echo "3. 检查系统日志：tail -f ~/.openclaw/logs/*.log"
    echo ""
    echo "如果无法解决，可能需要："
    echo "1. 重新安装OpenClaw"
    echo "2. 从完整备份恢复"
    echo "3. 联系系统管理员"
    echo ""
}

# 重启OpenClaw
restart_openclaw() {
    log_info "重启OpenClaw服务..."
    
    if command -v openclaw &> /dev/null; then
        if openclaw gateway restart; then
            log_info "OpenClaw重启成功"
            echo ""
            echo "✅ 恢复完成！"
            echo "请尝试访问OpenClaw Web界面"
        else
            log_warn "OpenClaw重启失败，请手动重启"
        fi
    else
        log_error "OpenClaw未安装"
        echo "请安装OpenClaw：npm install -g openclaw"
    fi
}

# 主函数
main() {
    echo "检测时间: $(date)"
    echo ""
    
    # 显示恢复选项
    show_recovery_options
    
    read -p "请选择恢复方式 [1-4]: " choice
    
    case $choice in
        1)
            local_recovery
            ;;
        2)
            github_recovery
            ;;
        3)
            basic_recovery
            ;;
        4)
            contact_support
            ;;
        *)
            log_error "无效选择"
            exit 1
            ;;
    esac
    
    echo ""
    echo "恢复完成时间: $(date)"
    echo "=========================================="
}

# 执行主函数
main "$@"