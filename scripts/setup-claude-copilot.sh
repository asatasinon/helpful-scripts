#!/usr/bin/env bash
set -euo pipefail

APP_NAME="copilot-api"
CLAUDE_DIR="$HOME/.claude"
BIN_DIR="$HOME/bin"
LOG_DIR="$HOME/.local/share/copilot-api"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

install_brew_dependency() {
  local command_name="$1"
  local package_name="$2"

  if command -v "$command_name" >/dev/null 2>&1; then
    echo "  - $package_name 已安装，跳过"
  else
    echo "  - 安装 $package_name"
    brew install "$package_name" >/dev/null
  fi
}

install_npm_global_package() {
  local package_name="$1"
  local binary_name="$2"

  if command -v "$binary_name" >/dev/null 2>&1; then
    echo "  - $package_name 已安装，跳过"
  else
    echo "  - 安装 $package_name"
    npm install -g "$package_name"
  fi
}

echo "==> Check Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew 未安装，请先安装："
  echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  exit 1
fi

echo "==> Install dependencies"
install_brew_dependency "node" "node"
install_brew_dependency "jq" "jq"

echo "==> Install global npm packages"
install_npm_global_package "pm2" "pm2"
install_npm_global_package "@anthropic-ai/claude-code" "claude"
install_npm_global_package "copilot-api" "copilot-api"

echo "==> Create directories"
mkdir -p "$CLAUDE_DIR" "$BIN_DIR" "$LOG_DIR"

echo "==> Write Claude settings"
cat > "$SETTINGS_FILE" <<'EOF'
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:4141",
    "ANTHROPIC_AUTH_TOKEN": "sk-dummy",
    "ANTHROPIC_MODEL": "sonnet",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "gpt-5-mini",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL_NAME": "GPT-5 mini",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL_DESCRIPTION": "0x multiplier · fast / background tasks",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL_SUPPORTED_CAPABILITIES": "tools,vision",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-4.6",
    "ANTHROPIC_DEFAULT_SONNET_MODEL_NAME": "Claude Sonnet 4.6",
    "ANTHROPIC_DEFAULT_SONNET_MODEL_DESCRIPTION": "1x multiplier · daily coding",
    "ANTHROPIC_DEFAULT_SONNET_MODEL_SUPPORTED_CAPABILITIES": "tools,vision",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "gpt-5.4",
    "ANTHROPIC_DEFAULT_OPUS_MODEL_NAME": "GPT-5.4",
    "ANTHROPIC_DEFAULT_OPUS_MODEL_DESCRIPTION": "1x multiplier · deep reasoning",
    "ANTHROPIC_DEFAULT_OPUS_MODEL_SUPPORTED_CAPABILITIES": "tools,vision",
    "ANTHROPIC_CUSTOM_MODEL_OPTION": "gpt-5.3-codex",
    "ANTHROPIC_CUSTOM_MODEL_OPTION_NAME": "GPT-5.3 Codex",
    "ANTHROPIC_CUSTOM_MODEL_OPTION_DESCRIPTION": "1x multiplier · best value for coding",
    "DISABLE_NON_ESSENTIAL_MODEL_CALLS": "1",
    "CLAUDE_CODE_ATTRIBUTION_HEADER": "0"
  }
}
EOF

echo "==> First-time Copilot auth"
echo
echo "现在会前台启动 copilot-api。"
echo "请按提示完成 GitHub Copilot 登录授权。"
echo "授权成功后，按 Ctrl+C 结束前台进程，脚本会继续。"
echo
copilot-api start --proxy-env || true

echo "==> Start copilot-api with pm2"
pm2 delete "$APP_NAME" >/dev/null 2>&1 || true
pm2 start "$(command -v copilot-api)" \
  --name "$APP_NAME" \
  -- start --proxy-env \
  --output "$LOG_DIR/copilot-api.out.log" \
  --error "$LOG_DIR/copilot-api.err.log"

echo "==> Save pm2 process list"
pm2 save

echo "==> Enable pm2 startup"
PM2_STARTUP_CMD="$(pm2 startup 2>/dev/null | tail -n 1 || true)"
if [[ -n "$PM2_STARTUP_CMD" ]]; then
  echo "Running: $PM2_STARTUP_CMD"
  eval "$PM2_STARTUP_CMD"
  pm2 save
fi

echo "==> Done"
echo
echo "配置文件: $SETTINGS_FILE"
echo "日志目录: $LOG_DIR"
echo
echo "后续常用命令："
echo "  pm2 status"
echo "  pm2 logs copilot-api"
echo "  pm2 restart copilot-api"