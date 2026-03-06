#!/bin/bash
#
# Pre-update Hook (Bash Version)
# 更新前执行，检查更新合法性
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
POST_ID=$(json_get "$CONTEXT" "post_id")
OLD_CONTENT=$(json_get "$CONTEXT" "old_content")
NEW_CONTENT=$(json_get "$CONTEXT" "new_content")
UPDATE_REASON=$(json_get "$CONTEXT" "update_reason")

# 设置默认值
POST_ID=${POST_ID:-""}
OLD_CONTENT=${OLD_CONTENT:-""}
NEW_CONTENT=${NEW_CONTENT:-""}
UPDATE_REASON=${UPDATE_REASON:-""}

# 1. 检查内容是否有实质变化
if [[ "$OLD_CONTENT" == "$NEW_CONTENT" ]]; then
    json_rejected "No content change detected"
    exit 0
fi

# 2. 检查更新频率（6小时内不重复更新）
VERSION_FILES=$(find "$ARCHIVE_DIR/fix" -name "${POST_ID}_v*.json" -type f 2>/dev/null | sort -V)

if [[ -n "$VERSION_FILES" ]]; then
    # 读取最新版本
    LATEST_VERSION=$(echo "$VERSION_FILES" | tail -1)

    if [[ -f "$LATEST_VERSION" ]]; then
        CREATED_AT=$(json_get "$(cat "$LATEST_VERSION")" "created_at")

        if [[ -n "$CREATED_AT" ]]; then
            # 计算时间差（小时）
            LAST_UPDATE=$(date -d "$CREATED_AT" +%s 2>/dev/null || echo "")
            NOW=$(date +%s)

            if [[ -n "$LAST_UPDATE" ]]; then
                HOURS_SINCE=$(( (NOW - LAST_UPDATE) / 3600 ))

                if [[ $HOURS_SINCE -lt 6 ]]; then
                    json_rejected "Too frequent updates (${HOURS_SINCE}h since last)"
                    exit 0
                fi
            fi
        fi
    fi
fi

# 3. 检查更新原因是否合理
REASON_LEN=${#UPDATE_REASON}
if [[ $REASON_LEN -lt 10 ]]; then
    json_rejected "Update reason too short (min 10 chars)"
    exit 0
fi

# 检查通过
CHECKS='{"content_changed": true, "update_frequency": "passed", "update_reason": "passed"}'
json_approved "$CHECKS"
