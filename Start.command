#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

if command -v python3 >/dev/null 2>&1; then
  exec python3 "$SCRIPT_DIR/scripts/launch_local.py"
fi

if command -v ruby >/dev/null 2>&1; then
  exec ruby "$SCRIPT_DIR/scripts/launch_local.rb"
fi

echo "python3 か ruby が見つからないため起動できません。"
echo "macOS の標準環境で動く想定ですが、必要なら別の配布方法に切り替えます。"
read -r -p "Enter キーで閉じます..."
