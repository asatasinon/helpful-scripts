#!/usr/bin/env bash
set -euo pipefail

echo "==> Detecting node..."
if ! command -v node >/dev/null 2>&1; then
  echo "❌ node 未安装"
  exit 1
fi

NODE_BIN="$(dirname "$(command -v node)")"
COPILOT_BIN="$(command -v copilot-api || true)"
PM2_BIN="$(command -v pm2 || true)"

echo "Node bin: $NODE_BIN"

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

install_if_missing() {
  local name="$1"
  local cmd="$2"
  if command_exists "$name"; then
    echo "✓ $name already installed"
  else
    echo "→ Installing $name ..."
    eval "$cmd"
  fi
}

echo "==> Checking Homebrew..."
if ! command_exists brew; then
  echo "❌ Homebrew 未安装，请先安装 brew"
  echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  exit 1
fi

echo "==> Installing dependencies..."
install_if_missing jq "brew install jq"

if ! command_exists pm2; then
  echo "→ Installing pm2 ..."
  npm install -g pm2
else
  echo "✓ pm2 already installed"
fi

if ! command_exists copilot-api; then
  echo "→ Installing copilot-api ..."
  npm install -g copilot-api
else
  echo "✓ copilot-api already installed"
fi

COPILOT_BIN="$(command -v copilot-api)"
PM2_BIN="$(command -v pm2)"

echo "copilot-api bin: $COPILOT_BIN"
echo "pm2 bin: $PM2_BIN"

echo "==> Creating directories..."
mkdir -p "$HOME/.claude"
mkdir -p "$HOME/copilot-api"
mkdir -p "$HOME/.local/share/copilot-api"

CLAUDE_SETTINGS="$HOME/.claude/settings.json"
PM2_CONFIG="$HOME/copilot-api/ecosystem.config.js"
ZSHRC_FILE="$HOME/.zshrc"

echo "==> Writing Claude Code settings..."
cat > "$CLAUDE_SETTINGS" <<'EOF'
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://127.0.0.1:4141",
    "ANTHROPIC_AUTH_TOKEN": "sk-dummy",
    "ANTHROPIC_MODEL": "sonnet",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-4.6",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-4.6",
    "DISABLE_NON_ESSENTIAL_MODEL_CALLS": "1",
    "CLAUDE_CODE_ATTRIBUTION_HEADER": "0"
  },
  "permissions": {
    "defaultMode": "bypassPermissions",
    "skipDangerousModePermissionPrompt": true
  }
}
EOF

echo "✓ Wrote $CLAUDE_SETTINGS"

echo "==> Writing PM2 ecosystem config..."
cat > "$PM2_CONFIG" <<EOF
module.exports = {
  apps: [
    {
      name: "copilot-api",
      script: "$COPILOT_BIN",
      args: "start --claude-code",
      interpreter: "none",
      exec_mode: "fork",
      instances: 1,
      cwd: process.env.HOME,
      autorestart: true,
      max_restarts: 10,
      min_uptime: "10s",
      restart_delay: 3000,
      exp_backoff_restart_delay: 100,
      max_memory_restart: "512M",
      watch: false,
      out_file: process.env.HOME + "/.local/share/copilot-api/copilot-api.out.log",
      error_file: process.env.HOME + "/.local/share/copilot-api/copilot-api.err.log",
      merge_logs: true,
      log_date_format: "YYYY-MM-DD HH:mm:ss Z",
      time: true,
      kill_timeout: 5000,
      env: {
        PATH: "$NODE_BIN:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin",
        HOME: process.env.HOME
      }
    }
  ]
};
EOF

echo "✓ Wrote $PM2_CONFIG"

echo "==> Adding zsh aliases..."
if ! grep -q "alias claude-dev='claude --model sonnet'" "$ZSHRC_FILE" 2>/dev/null; then
  cat >> "$ZSHRC_FILE" <<'EOF'

# ===== Claude Code + copilot-api (direct) =====
alias claude-dev='claude --model sonnet'
alias claude-brain='claude --model opus'

alias copilot-status='pm2 status'
alias copilot-log='pm2 logs copilot-api'
alias copilot-restart='pm2 restart copilot-api'
EOF
  echo "✓ zsh aliases added"
else
  echo "✓ zsh aliases already exist"
fi

echo "==> First-time Copilot login..."
echo "接下来会前台启动 copilot-api。"
echo "如果之前没登录，请按提示完成 GitHub Copilot 授权。"
echo "授权完成后，按 Ctrl+C 结束前台进程，脚本会继续。"
echo

set +e
"$COPILOT_BIN" start --proxy-env
set -e

echo "==> Starting copilot-api with PM2..."
pm2 delete copilot-api >/dev/null 2>&1 || true
pm2 start "$PM2_CONFIG"
pm2 save

echo "==> Installing pm2-logrotate..."
pm2 install pm2-logrotate >/dev/null 2>&1 || true
pm2 set pm2-logrotate:max_size 10M >/dev/null
pm2 set pm2-logrotate:retain 7 >/dev/null
pm2 set pm2-logrotate:compress true >/dev/null
pm2 set pm2-logrotate:dateFormat YYYY-MM-DD_HH-mm-ss >/dev/null

echo
echo "==> Done"
echo "执行以下命令："
echo "  source ~/.zshrc"
echo "  copilot-status"
echo "  claude-dev"
echo
echo "首次进入 Claude 后建议执行一次："
echo "  /logout"
echo
echo "常用命令："
echo "  claude-dev       # Claude Sonnet 4.6"
echo "  claude-brain     # Claude Opus 4.6"
echo "  copilot-status"
echo "  copilot-log"
echo "  copilot-restart"