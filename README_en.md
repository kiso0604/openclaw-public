# OpenClaw Public Recovery Repository

This repository contains public recovery scripts for OpenClaw.
Full data is in private repository and requires GitHub token access.

## Recovery Commands
```bash
# Method 1: Direct execution
curl -sSL https://raw.githubusercontent.com/kiso0604/openclaw-public/main/safe_recovery.sh | bash

# Method 2: Download and run
curl -sSL https://raw.githubusercontent.com/kiso0604/openclaw-public/main/safe_recovery.sh -o recovery.sh
chmod +x recovery.sh
./recovery.sh
```

## Requirements
1. GitHub access token (requires `repo` permission)
2. Token URL: https://github.com/settings/tokens

## Recovery Process
1. Script will prompt for GitHub token
2. Use token to recover data from private repository
3. Restart OpenClaw service
4. Verify recovery integrity

## Emergency Recovery
If unable to access, use local backup:
```bash
cd ~/OpenClawBackups
tar -xzf latest_backup.tar.gz -C ~/openclaw/workspace
openclaw gateway restart
```

---
**Last Updated**: 2026-03-04
**Maintainer**: 善财 🐕💻
