# OpenClaw公开恢复仓库

此仓库包含OpenClaw的公开恢复脚本。
完整数据在私有仓库中，需要使用GitHub令牌访问。

## 恢复命令
```bash
# 方法1：直接运行
curl -sSL https://raw.githubusercontent.com/kiso0604/openclaw-public/main/安全恢复脚本.sh | bash

# 方法2：下载后运行
curl -sSL https://raw.githubusercontent.com/kiso0604/openclaw-public/main/安全恢复脚本.sh -o 恢复.sh
chmod +x 恢复.sh
./恢复.sh
```

## 需要准备
1. GitHub访问令牌（需要`repo`权限）
2. 令牌获取：https://github.com/settings/tokens

## 恢复流程
1. 脚本会引导输入GitHub令牌
2. 使用令牌从私有仓库恢复数据
3. 重启OpenClaw服务
4. 验证恢复完整性

## 紧急情况
如果无法访问，请使用本地备份：
```bash
cd ~/OpenClawBackups
tar -xzf 最新备份.tar.gz -C ~/openclaw/workspace
openclaw gateway restart
```

---
**最后更新**：2026-03-04
**维护者**：善财 🐕💻
