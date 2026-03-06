#!/bin/bash
#
# Pre-generate Hook (Bash Version)
# 在 AI 生成内容前执行，检查配额、话题重复等
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

init

# 检查参数
if [[ $# -lt 1 ]]; then
    error_exit "No context file provided"
fi

CONTEXT_FILE="$1"

# 读取上下文
if [[ ! -f "$CONTEXT_FILE" ]]; then
    error_exit "Context file not found: $CONTEXT_FILE"
fi

CONTEXT=$(cat "$CONTEXT_FILE")

# 提取字段
PERSONA_JSON=$(json_get "$CONTEXT" "persona")
ACTION=$(json_get "$CONTEXT" "action")
TITLE=$(json_get "$CONTEXT" "title")
CATEGORY=$(json_get "$CONTEXT" "category")

PERSONA_ID=$(json_get "$PERSONA_JSON" "id")

# 设置默认值
ACTION=${ACTION:-"create"}
TITLE=${TITLE:-""}
CATEGORY=${CATEGORY:-""}
PERSONA_ID=${PERSONA_ID:-"unknown"}

# 1. 检查今日发帖配额
TODAY_POSTS=$(get_today_post_count "$PERSONA_ID")
DAILY_LIMIT_RAW=$(get_persona_daily_limit "$PERSONA_JSON")
DAILY_LIMIT=${DAILY_LIMIT_RAW:-3}

if [[ $TODAY_POSTS -ge $DAILY_LIMIT ]]; then
    json_rejected "Daily post limit reached ($TODAY_POSTS/$DAILY_LIMIT)"
    exit 0
fi

# 2. 检查话题重复（最近 20 条）
RECENT_POSTS=$(find "$CONTENT_DIR/published" -name "post_*_${PERSONA_ID}.json" -type f 2>/dev/null | sort -r | head -20)

for post_file in $RECENT_POSTS; do
    if [[ -f "$post_file" ]]; then
        EXISTING_TITLE=$(json_get "$(cat "$post_file")" "title")
        # 简单包含检查（不区分大小写）
        if [[ -n "$TITLE" && -n "$EXISTING_TITLE" ]]; then
            TITLE_LOWER=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]')
            EXISTING_LOWER=$(echo "$EXISTING_TITLE" | tr '[:upper:]' '[:lower:]')
            if [[ "$EXISTING_LOWER" == *"$TITLE_LOWER"* || "$TITLE_LOWER" == *"$EXISTING_LOWER"* ]]; then
                json_rejected "Similar title found in recent post: $EXISTING_TITLE"
                exit 0
            fi
        fi
    fi
done

# 3. 检查是否在活跃时段
ACTIVE_HOURS=$(get_persona_active_hours "$PERSONA_JSON")
if [[ -n "$ACTIVE_HOURS" ]]; then
    START_HOUR=$(echo "$ACTIVE_HOURS" | awk '{print $1}')
    END_HOUR=$(echo "$ACTIVE_HOURS" | awk '{print $2}')

    if [[ -n "$START_HOUR" && -n "$END_HOUR" ]]; then
        if ! check_active_hours "$START_HOUR" "$END_HOUR"; then
            json_rejected "Outside active hours (${START_HOUR}:00-${END_HOUR}:00)"
            exit 0
        fi
    fi
fi

# 检查通过
CHECKS="{\"daily_quota\": \"$TODAY_POSTS/$DAILY_LIMIT\", \"duplicate_check\": \"passed\", \"active_hours\": \"passed\"}"
json_approved "$CHECKS"
