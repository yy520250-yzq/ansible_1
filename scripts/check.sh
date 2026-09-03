#!/usr/bin/env bash
# 提交前自检:语法检查 + localhost 全专项冒烟
# 用法: scripts/check.sh
set -euo pipefail
cd "$(dirname "$0")/.."

echo "[1/2] ansible 语法检查..."
ansible-playbook --syntax-check playbooks/inspect.yml

echo "[2/2] localhost 全专项冒烟(输出报告到 ~/ops-healthcheck)..."
ansible-playbook playbooks/inspect.yml

echo "自检通过 ✔  可提交推送。"
