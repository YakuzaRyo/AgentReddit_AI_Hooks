#!/bin/bash
#
# Update Post - 更新帖子 (Bash Version)
# 用法: update_post.sh <post_id> <new_content> <update_reason>
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

init

# 参数检查
if [[ $# -lt 3 ]]; then
    error_exit "Usage: $0 <post_id> <new_content> <update_reason>"
fi

POST_ID="$1"
NEW_CONTENT="$2"
UPDATE_REASON="$3"

# 1. 检查帖子是否存在
PUBLISHED_PATH="$CONTENT_DIR/published/${POST_ID}.json"

if [[ ! -f "$PUBLISHED_PATH" ]]; then
    error_exit "Post not found: $POST_ID"
fi

POST_DATA=$(cat "$PUBLISHED_PATH")
OLD_CONTENT=$(json_get "$POST_DATA" "content")
PERSONA_ID=$(json_get "$POST_DATA" "persona_id")

OLD_CONTENT=${OLD_CONTENT:-""}
PERSONA_ID=${PERSONA_ID:-""}

# 加载角色配置
PERSONA_JSON=$(load_persona "$PERSONA_ID")
PERSONA_NAME=$(json_get "$PERSONA_JSON" "name")
PERSONA_NAME=${PERSONA_NAME:-"Unknown"}

log "[$PERSONA_NAME] Updating post: $POST_ID"

# 2. Pre-update hook
PRE_UPDATE_CONTEXT="{\"persona\": $PERSONA_JSON, \"post_id\": \"$POST_ID\", \"old_content\": \"$OLD_CONTENT\", \"new_content\": \"$NEW_CONTENT\", \"update_reason\": \"$UPDATE_REASON\"}"

PRE_UPDATE_FILE=$(mktemp)
echo "$PRE_UPDATE_CONTEXT" > "$PRE_UPDATE_FILE"
PRE_UPDATE_RESULT=$("$SCRIPT_DIR/hooks/pre_update.sh" "$PRE_UPDATE_FILE")
rm -f "$PRE_UPDATE_FILE"

PRE_UPDATE_STATUS=$(json_get "$PRE_UPDATE_RESULT" "status")
if [[ "$PRE_UPDATE_STATUS" == "rejected" ]]; then
    REASON=$(json_get "$PRE_UPDATE_RESULT" "reason")
    log "Pre-update rejected: $REASON"
    echo "{\"status\": \"rejected\", \"reason\": \"$REASON\"}"
    exit 0
fi

# 3. 获取上一个版本
PARENT_VERSION=$(get_latest_version "$POST_ID")
PARENT_VERSION_STR="null"
if [[ $PARENT_VERSION -gt 0 ]]; then
    PARENT_VERSION_STR="\"v${PARENT_VERSION}\""
fi

# 4. 更新内容
UPDATED_POST=$(json_set "$POST_DATA" "content" "$NEW_CONTENT")
UPDATED_POST=$(json_set "$UPDATED_POST" "updated_at" "$(get_iso_time)")
UPDATED_POST=$(json_set "$UPDATED_POST" "update_reason" "$UPDATE_REASON")

write_json_file "$PUBLISHED_PATH" "$UPDATED_POST"

# 5. ACE 记录
CONTENT_HASH=$(get_content_hash "$NEW_CONTENT")
ACE_VERSION=$(get_next_version "$POST_ID")

ACE_DATA="{\"post_id\": \"$POST_ID\", \"version\": $ACE_VERSION, \"parent_version\": $PARENT_VERSION_STR, \"change_type\": \"update\", \"content_hash\": \"$CONTENT_HASH\", \"created_at\": \"$(get_iso_time)\", \"change_reason\": \"$UPDATE_REASON\"}"

ACE_PATH="$ARCHIVE_DIR/fix/${POST_ID}_v${ACE_VERSION}.json"
write_json_file "$ACE_PATH" "$ACE_DATA"

# 6. Git 提交
if command -v git &> /dev/null && git rev-parse --git-dir &> /dev/null 2>&1; then
    git add -A "$CONTENT_DIR" "$ARCHIVE_DIR" &> /dev/null || true
    git commit -m "ace: $PERSONA_ID update $POST_ID v$ACE_VERSION" --quiet &> /dev/null || true
fi

# 7. Post-update hook (使用 post_publish 作为简化)
POST_UPDATE_CONTEXT="{\"post_id\": \"$POST_ID\", \"persona\": $PERSONA_JSON, \"ace_version\": $ACE_DATA}"

POST_UPDATE_FILE=$(mktemp)
echo "$POST_UPDATE_CONTEXT" > "$POST_UPDATE_FILE"
"$SCRIPT_DIR/hooks/post_publish.sh" "$POST_UPDATE_FILE" > /dev/null 2>&1 || true
rm -f "$POST_UPDATE_FILE"

log "Post updated: $POST_ID -> v$ACE_VERSION"

# 返回结果
echo "{\"status\": \"updated\", \"post_id\": \"$POST_ID\", \"version\": $ACE_VERSION, \"change_reason\": \"$UPDATE_REASON\"}"
