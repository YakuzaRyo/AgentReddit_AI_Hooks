#!/usr/bin/env bash
# Skill Eval Wrapper - Unix (macOS/Linux)
# Cross-platform hook execution wrapper for skill-forced-eval

# === 配置 ===
# 日志文件路径（相对于项目根目录）
LOG_FILE=".claude/logs/skill-eval.log"
# 是否启用详细日志（通过环境变量控制）
DEBUG=${CLAUDE_HOOK_DEBUG:-0}

# === 日志函数 ===
log() {
    local level=$1
    shift
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
    if [ "$DEBUG" = "1" ]; then
        echo "$msg" >&2
    fi
    # 写入日志文件（静默失败）
    mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null
    echo "$msg" >> "$LOG_FILE" 2>/dev/null || true
}

log "INFO" "=== skill-eval-wrapper.sh started ==="
log "INFO" "USER_PROMPT: ${USER_PROMPT:-<empty>}"

# === 环境变量逃生通道 ===
if [ "${CLAUDE_NO_HOOKS}" = "1" ] || [ "${CLAUDE_SKIP_SKILL_EVAL}" = "1" ]; then
    log "INFO" "Hook disabled via environment variable"
    exit 0
fi

# === 斜杠命令逃生通道 ===
if echo "${USER_PROMPT:-}" | grep -qE '^\/'; then
    log "INFO" "Command detected, skipping eval"
    exit 0
fi

# === 获取脚本目录 ===
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
log "INFO" "Hook directory: $HOOK_DIR"

# 检查 Node.js 是否可用
if ! command -v node >/dev/null 2>&1; then
    log "ERROR" "Node.js not found in PATH"
    exit 0
fi

log "INFO" "Node.js version: $(node --version 2>&1)"

# === 执行评估脚本 ===
# Try .cjs first (ES Module projects)
CJS_SCRIPT="$HOOK_DIR/skill-forced-eval.cjs"
if [ -f "$CJS_SCRIPT" ]; then
    log "INFO" "Executing: $CJS_SCRIPT"
    node "$CJS_SCRIPT" 2>&1
    local exit_code=$?
    log "INFO" "Exit code: $exit_code"
    exit $exit_code
fi

# Fallback to .js (CommonJS projects)
JS_SCRIPT="$HOOK_DIR/skill-forced-eval.js"
if [ -f "$JS_SCRIPT" ]; then
    log "INFO" "Executing: $JS_SCRIPT"
    node "$JS_SCRIPT" 2>&1
    local exit_code=$?
    log "INFO" "Exit code: $exit_code"
    exit $exit_code
fi

# No script found
log "WARN" "No skill-forced-eval script found in $HOOK_DIR"
exit 0
