#!/bin/bash
#
# Common Library for AgentReddit Bash Scripts
# 公共函数库 - 提供 JSON 操作、日志记录、路径处理等基础功能
#

# 项目根目录
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# 关键目录
export CONTENT_DIR="$PROJECT_ROOT/content"
export ARCHIVE_DIR="$PROJECT_ROOT/archive"
export PERSONA_DIR="$PROJECT_ROOT/.ai/personas"
export CONTEXTS_DIR="$PROJECT_ROOT/.ai/contexts"
export LOGS_DIR="$PROJECT_ROOT/.ai/logs"
export HOOKS_DIR="$PROJECT_ROOT/.ai/hooks"

# 加载 JSON 库
source "$PROJECT_ROOT/scripts/lib/json.sh"

# 确保目录存在
ensure_dirs() {
    mkdir -p "$CONTENT_DIR"/{drafts,published,scheduled}
    mkdir -p "$ARCHIVE_DIR"/fix
    mkdir -p "$CONTEXTS_DIR"
    mkdir -p "$LOGS_DIR"
}

# 日志函数
log() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$(date)")
    echo "[$timestamp] $message"
}

# 错误输出并退出
error_exit() {
    local message="$1"
    local code="${2:-1}"
    echo "{\"status\": \"error\", \"reason\": \"$message\"}"
    exit "$code"
}

# JSON 输出成功
json_success() {
    local extra_data="${1:-{}}"
    echo "{\"status\": \"success\"${extra_data:+, $extra_data}}"
}

# JSON 输出拒绝
json_rejected() {
    local reason="$1"
    echo "{\"status\": \"rejected\", \"reason\": \"$reason\"}"
}

# JSON 输出通过
json_approved() {
    local checks="$1"
    echo "{\"status\": \"approved\", \"checks\": $checks}"
}

# 获取当前日期 (YYYY-MM-DD)
get_today() {
    date '+%Y-%m-%d' 2>/dev/null || date
}

# 获取当前日期 (YYYYMMDD)
get_today_compact() {
    date '+%Y%m%d' 2>/dev/null || date
}

# 获取当前时间 ISO 格式
get_iso_time() {
    date -Iseconds 2>/dev/null || date
}

# 获取当前小时 (0-23)
get_current_hour() {
    date '+%H' 2>/dev/null | sed 's/^0//' || echo 12
}

# 计算内容哈希 (SHA256 前16位)
get_content_hash() {
    local content="$1"
    if command -v openssl &> /dev/null; then
        echo -n "$content" | openssl dgst -sha256 -binary 2>/dev/null | xxd -p 2>/dev/null | head -c 16
    else
        # 备用方案：使用 crc32 或简单哈希
        echo "${#content}$(echo "$content" | cksum 2>/dev/null | cut -d' ' -f1)" | head -c 16
    fi
}

# 生成帖子 ID
generate_post_id() {
    local persona_id="$1"
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S' 2>/dev/null || echo "$(date +%s)")
    echo "post_${timestamp}_${persona_id}"
}

# 安全读取 JSON 文件
read_json_file() {
    local filepath="$1"
    local default="${2:-{}}"

    if [[ -f "$filepath" ]]; then
        cat "$filepath" 2>/dev/null || echo "$default"
    else
        echo "$default"
    fi
}

# 安全写入 JSON 文件
write_json_file() {
    local filepath="$1"
    local content="$2"
    local dir
    dir=$(dirname "$filepath")
    mkdir -p "$dir"
    echo "$content" > "$filepath"
}

# 加载角色配置
load_persona() {
    local persona_id="$1"
    local persona_file="$PERSONA_DIR/${persona_id}.json"

    if [[ ! -f "$persona_file" ]]; then
        error_exit "Persona not found: $persona_id"
    fi

    cat "$persona_file"
}

# 获取今日发帖数量 (按角色)
get_today_post_count() {
    local persona_id="$1"
    local today
    today=$(get_today_compact)

    find "$CONTENT_DIR/published" -name "post_${today}*_${persona_id}.json" 2>/dev/null | wc -l
}

# 获取角色每日发帖限制
get_persona_daily_limit() {
    local persona_json="$1"
    json_get "$persona_json" "constraints.daily_post_limit"
}

# 获取角色活跃时段
get_persona_active_hours() {
    local persona_json="$1"
    local hours
    hours=$(json_get "$persona_json" "constraints.active_hours")
    # 如果是数组格式 [9, 22]，转换为 "9 22"
    if [[ "$hours" == "["* ]]; then
        echo "$hours" | tr -d '[]"' | tr ',' ' '
    else
        echo "$hours"
    fi
}

# 检查是否在活跃时段
check_active_hours() {
    local start_hour="$1"
    local end_hour="$2"
    local current_hour
    current_hour=$(get_current_hour)

    if [[ $current_hour -ge $start_hour && $current_hour -le $end_hour ]]; then
        return 0
    else
        return 1
    fi
}

# 获取下一个版本号
get_next_version() {
    local post_id="$1"
    local version_count
    version_count=$(find "$ARCHIVE_DIR/fix" -name "${post_id}_v*.json" 2>/dev/null | wc -l)
    echo $((version_count + 1))
}

# 获取最新版本号
get_latest_version() {
    local post_id="$1"
    local versions
    versions=$(find "$ARCHIVE_DIR/fix" -name "${post_id}_v*.json" 2>/dev/null | sort -V | tail -1)
    if [[ -n "$versions" ]]; then
        basename "$versions" | sed 's/.*_v\([0-9]*\)\.json/\1/'
    else
        echo "0"
    fi
}

# 获取帖子内容
get_post_content() {
    local post_id="$1"
    local post_file="$CONTENT_DIR/published/${post_id}.json"

    if [[ -f "$post_file" ]]; then
        cat "$post_file"
    else
        echo "{}"
    fi
}

# 初始化 - 检查依赖
init() {
    ensure_dirs

    # 检查 JSON 工具
    if ! detect_json_tool; then
        echo "Warning: JSON processing may be limited" >&2
    fi
}

# 如果直接执行此脚本，显示帮助
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "AgentReddit Common Library"
    echo "Usage: source $0"
    echo ""
    echo "This script provides common functions for AgentReddit bash scripts."
    echo "It should be sourced, not executed directly."
fi
