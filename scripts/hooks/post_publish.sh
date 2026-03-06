#!/bin/bash
#
# Post-publish Hook (Bash Version)
# 发布后执行，记录日志、更新统计等
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

init

# 检查参数
if [[ $# -lt 1 ]]; then
    echo '{"status": "skipped"}'
    exit 0
fi

CONTEXT_FILE="$1"

# 读取上下文
if [[ ! -f "$CONTEXT_FILE" ]]; then
    echo '{"status": "skipped", "reason": "Context file not found"}'
    exit 0
fi

CONTEXT=$(cat "$CONTEXT_FILE")

# 提取字段
POST_ID=$(json_get "$CONTEXT" "post_id")
PERSONA_JSON=$(json_get "$CONTEXT" "persona")
ACE_VERSION=$(json_get "$CONTEXT" "ace_version")

PERSONA_ID=$(json_get "$PERSONA_JSON" "id")
ACE_VER=$(json_get "$ACE_VERSION" "version")
CHANGE_TYPE=$(json_get "$ACE_VERSION" "change_type")

# 设置默认值
POST_ID=${POST_ID:-""}
PERSONA_ID=${PERSONA_ID:-"unknown"}
ACE_VER=${ACE_VER:-1}
CHANGE_TYPE=${CHANGE_TYPE:-"create"}

TODAY=$(get_today)
TODAY_LOG_FILE="$LOGS_DIR/posts_${TODAY}.json"

# 1. 更新今日发帖记录
TODAY_POSTS=$(read_json_file "$TODAY_LOG_FILE" "[]")

NEW_ENTRY="{\"post_id\": \"$POST_ID\", \"persona\": \"$PERSONA_ID\", \"title\": \"$POST_ID\", \"published_at\": \"$(get_iso_time)\", \"ace_version\": $ACE_VER}"
TODAY_POSTS=$(json_array_append "$TODAY_POSTS" "$NEW_ENTRY")
write_json_file "$TODAY_LOG_FILE" "$TODAY_POSTS"

# 2. 更新统计
STATS_FILE="$CONTEXTS_DIR/stats.json"
STATS=$(read_json_file "$STATS_FILE" '{"total_posts": 0, "total_updates": 0}')

TOTAL_POSTS=$(json_get "$STATS" "total_posts")
TOTAL_UPDATES=$(json_get "$STATS" "total_updates")

TOTAL_POSTS=${TOTAL_POSTS:-0}
TOTAL_UPDATES=${TOTAL_UPDATES:-0}

if [[ "$CHANGE_TYPE" == "create" ]]; then
    TOTAL_POSTS=$((TOTAL_POSTS + 1))
else
    TOTAL_UPDATES=$((TOTAL_UPDATES + 1))
fi

STATS="{\"total_posts\": $TOTAL_POSTS, \"total_updates\": $TOTAL_UPDATES}"
write_json_file "$STATS_FILE" "$STATS"

# 3. 更新今日发帖上下文
TODAY_POSTS_FILE="$CONTEXTS_DIR/today_posts.json"
TODAY_DATA=$(read_json_file "$TODAY_POSTS_FILE" "{\"date\": \"$TODAY\", \"posts\": []}")

# 检查是否是今天的数据
CURRENT_DATE=$(json_get "$TODAY_DATA" "date")
if [[ "$CURRENT_DATE" != "$TODAY" ]]; then
    TODAY_DATA="{\"date\": \"$TODAY\", \"posts\": []}"
fi

POST_ENTRY="{\"id\": \"$POST_ID\", \"title\": \"$POST_ID\", \"persona\": \"$PERSONA_ID\", \"published_at\": \"$(get_iso_time)\"}"
TODAY_POSTS_LIST=$(json_get "$TODAY_DATA" "posts")
TODAY_POSTS_LIST=$(json_array_append "$TODAY_POSTS_LIST" "$POST_ENTRY")
TODAY_DATA=$(json_set "$TODAY_DATA" "posts" "$TODAY_POSTS_LIST")
write_json_file "$TODAY_POSTS_FILE" "$TODAY_DATA"

# 返回结果
echo '{"status": "completed", "actions": ["updated_today_log", "updated_stats", "updated_today_context"]}'
