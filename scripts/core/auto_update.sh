#!/bin/bash
#
# Auto Update Post - AI 自主判断是否更新帖子
# 用法: auto_update.sh <post_id> [persona_id]
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

init

# 参数检查
if [[ $# -lt 1 ]]; then
    error_exit "Usage: $0 <post_id> [persona_id]"
fi

POST_ID="$1"

# 获取帖子内容
PUBLISHED_PATH="$CONTENT_DIR/published/${POST_ID}.json"

if [[ ! -f "$PUBLISHED_PATH" ]]; then
    error_exit "Post not found: $POST_ID"
fi

POST_DATA=$(cat "$PUBLISHED_PATH")
CURRENT_CONTENT=$(json_get "$POST_DATA" "content")
PERSONA_ID=$(json_get "$POST_DATA" "persona_id")

CURRENT_CONTENT=${CURRENT_CONTENT:-""}
PERSONA_ID=${PERSONA_ID:-""}

# 如果提供了 persona_id 参数，使用它
if [[ -n "${2:-}" ]]; then
    PERSONA_ID="$2"
fi

# 加载角色配置
PERSONA_JSON=$(load_persona "$PERSONA_ID")
PERSONA_NAME=$(json_get "$PERSONA_JSON" "name")
PERSONA_NAME=${PERSONA_NAME:-"Unknown"}

# 判断是否应更新
should_update_post() {
    local post_id="$1"
    local current_content="$2"

    # 获取帖子历史版本
    local latest_version
    latest_version=$(get_latest_version "$post_id")

    # 如果这是第一次创建，不需要更新
    if [[ $latest_version -eq 0 ]]; then
        echo "false|New post, no update needed"
        return
    fi

    # 读取最新版本的创建时间
    local ace_file="$ARCHIVE_DIR/fix/${post_id}_v${latest_version}.json"
    if [[ ! -f "$ace_file" ]]; then
        echo "false|No version history found"
        return
    fi

    local created_at
    created_at=$(json_get "$(cat "$ace_file")" "created_at")

    if [[ -z "$created_at" ]]; then
        echo "false|No creation time found"
        return
    fi

    # 计算时间差
    local last_update now hours_since
    last_update=$(date -d "$created_at" +%s 2>/dev/null || echo "")
    now=$(date +%s)

    if [[ -z "$last_update" ]]; then
        echo "false|Could not parse date"
        return
    fi

    hours_since=$(( (now - last_update) / 3600 ))

    # 规则：24小时内不重复更新
    if [[ $hours_since -lt 24 ]]; then
        echo "false|Last update was ${hours_since} hours ago"
        return
    fi

    # 可以更新
    echo "true|Content may be outdated (last update ${hours_since}h ago)"
}

# 判断是否需要更新
SHOULD_UPDATE_RESULT=$(should_update_post "$POST_ID" "$CURRENT_CONTENT")
SHOULD_UPDATE=$(echo "$SHOULD_UPDATE_RESULT" | cut -d'|' -f1)
REASON=$(echo "$SHOULD_UPDATE_RESULT" | cut -d'|' -f2)

if [[ "$SHOULD_UPDATE" != "true" ]]; then
    log "Auto-update skipped for $POST_ID: $REASON"
    echo "{\"status\": \"skipped\", \"reason\": \"$REASON\"}"
    exit 0
fi

# 生成新内容（这里简化处理，实际应调用 AI 生成）
NEW_CONTENT="${CURRENT_CONTENT}

[Updated] ${REASON}"

# 执行更新
"$SCRIPT_DIR/core/update_post.sh" "$POST_ID" "$NEW_CONTENT" "$REASON"
