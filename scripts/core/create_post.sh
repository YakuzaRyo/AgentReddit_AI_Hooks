#!/bin/bash
#
# Create Post - 创建新帖子 (Bash Version)
# 用法: create_post.sh <persona_id> <title> <content> <category> <tags_json>
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

init

# 参数检查
if [[ $# -lt 4 ]]; then
    error_exit "Usage: $0 <persona_id> <title> <content> <category> [tags_json]"
fi

PERSONA_ID="$1"
TITLE="$2"
CONTENT="$3"
CATEGORY="${4:-general}"
TAGS_JSON="${5:-[\"general\"]}"

# 加载角色配置
PERSONA_JSON=$(load_persona "$PERSONA_ID")
PERSONA_NAME=$(json_get "$PERSONA_JSON" "name")
PERSONA_NAME=${PERSONA_NAME:-"Unknown"}

log "[$PERSONA_NAME] Creating post: $TITLE"

# 1. Pre-generate hook
PRE_GEN_CONTEXT="{\"persona\": $PERSONA_JSON, \"action\": \"create\", \"title\": \"$TITLE\", \"category\": \"$CATEGORY\"}"

PRE_GEN_FILE=$(mktemp)
echo "$PRE_GEN_CONTEXT" > "$PRE_GEN_FILE"
PRE_GEN_RESULT=$("$SCRIPT_DIR/hooks/pre_generate.sh" "$PRE_GEN_FILE")
rm -f "$PRE_GEN_FILE"

PRE_GEN_STATUS=$(json_get "$PRE_GEN_RESULT" "status")
if [[ "$PRE_GEN_STATUS" == "rejected" ]]; then
    REASON=$(json_get "$PRE_GEN_RESULT" "reason")
    log "Pre-generate rejected: $REASON"
    echo "{\"status\": \"rejected\", \"reason\": \"$REASON\"}"
    exit 0
fi

# 2. Pre-publish hook
PRE_PUB_CONTEXT="{\"persona\": $PERSONA_JSON, \"title\": \"$TITLE\", \"content\": \"$CONTENT\", \"tags\": $TAGS_JSON}"

PRE_PUB_FILE=$(mktemp)
echo "$PRE_PUB_CONTEXT" > "$PRE_PUB_FILE"
PRE_PUB_RESULT=$("$SCRIPT_DIR/hooks/pre_publish.sh" "$PRE_PUB_FILE")
rm -f "$PRE_PUB_FILE"

PRE_PUB_STATUS=$(json_get "$PRE_PUB_RESULT" "status")
if [[ "$PRE_PUB_STATUS" == "rejected" ]]; then
    REASON=$(json_get "$PRE_PUB_RESULT" "reason")
    log "Pre-publish rejected: $REASON"
    echo "{\"status\": \"rejected\", \"reason\": \"$REASON\"}"
    exit 0
fi

# 3. 生成帖子 ID
POST_ID=$(generate_post_id "$PERSONA_ID")

# 4. 保存到草稿
DRAFT_PATH="$CONTENT_DIR/drafts/${POST_ID}.md"
DRAFT_DATA="{\"id\": \"$POST_ID\", \"title\": \"$TITLE\", \"content\": \"$CONTENT\", \"category\": \"$CATEGORY\", \"tags\": $TAGS_JSON, \"author\": \"$PERSONA_NAME\", \"persona_id\": \"$PERSONA_ID\", \"created_at\": \"$(get_iso_time)\", \"status\": \"draft\"}"

write_json_file "$DRAFT_PATH" "$DRAFT_DATA"

# 5. 移动到 published
PUBLISHED_PATH="$CONTENT_DIR/published/${POST_ID}.json"
PUBLISHED_DATA=$(json_set "$DRAFT_DATA" "status" "published")
PUBLISHED_DATA=$(json_set "$PUBLISHED_DATA" "published_at" "$(get_iso_time)")

write_json_file "$PUBLISHED_PATH" "$PUBLISHED_DATA"

# 6. ACE 记录
CONTENT_HASH=$(get_content_hash "$CONTENT")
ACE_VERSION=$(get_next_version "$POST_ID")

ACE_DATA="{\"post_id\": \"$POST_ID\", \"version\": $ACE_VERSION, \"parent_version\": null, \"change_type\": \"create\", \"content_hash\": \"$CONTENT_HASH\", \"created_at\": \"$(get_iso_time)\", \"change_reason\": \"Initial post creation\"}"

ACE_PATH="$ARCHIVE_DIR/fix/${POST_ID}_v${ACE_VERSION}.json"
write_json_file "$ACE_PATH" "$ACE_DATA"

# 7. Git 提交 (如果可用)
if command -v git &> /dev/null && git rev-parse --git-dir &> /dev/null 2>&1; then
    git add -A "$CONTENT_DIR" "$ARCHIVE_DIR" "$CONTEXTS_DIR" "$LOGS_DIR" &> /dev/null || true
    git commit -m "ace: $PERSONA_ID create $POST_ID" --quiet &> /dev/null || true
fi

# 8. Post-publish hook
POST_PUB_CONTEXT="{\"post_id\": \"$POST_ID\", \"persona\": $PERSONA_JSON, \"ace_version\": $ACE_DATA}"

POST_PUB_FILE=$(mktemp)
echo "$POST_PUB_CONTEXT" > "$POST_PUB_FILE"
"$SCRIPT_DIR/hooks/post_publish.sh" "$POST_PUB_FILE" > /dev/null 2>&1 || true
rm -f "$POST_PUB_FILE"

log "Post created: $POST_ID"

# 返回结果
echo "{\"status\": \"created\", \"post_id\": \"$POST_ID\", \"ace_version\": $ACE_VERSION}"
