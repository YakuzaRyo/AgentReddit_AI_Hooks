#!/bin/bash
#
# Pre-publish Hook (Bash Version)
# 在发布前执行，检查内容安全、格式等
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
TITLE=$(json_get "$CONTEXT" "title")
CONTENT=$(json_get "$CONTEXT" "content")
TAGS_JSON=$(json_get "$CONTEXT" "tags")
PERSONA_JSON=$(json_get "$CONTEXT" "persona")

# 设置默认值
TITLE=${TITLE:-""}
CONTENT=${CONTENT:-""}
TAGS_JSON=${TAGS_JSON:-"[]"}
PERSONA_JSON=${PERSONA_JSON:-"{}"}

# 1. 敏感词检查
check_sensitive_words() {
    local content="$1"
    local banned_file="$CONTEXTS_DIR/banned_words.txt"

    if [[ ! -f "$banned_file" ]]; then
        return 0
    fi

    local content_lower
    content_lower=$(echo "$content" | tr '[:upper:]' '[:lower:]')

    while IFS= read -r word || [[ -n "$word" ]]; do
        word=$(echo "$word" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
        if [[ -n "$word" && "$content_lower" == *"$word"* ]]; then
            echo "$word"
            return 1
        fi
    done < "$banned_file"

    return 0
}

SENSITIVE_WORD=$(check_sensitive_words "$CONTENT")
if [[ $? -ne 0 ]]; then
    json_rejected "Sensitive words found: $SENSITIVE_WORD"
    exit 0
fi

# 2. 格式检查
ISSUES="[]"

# 标题长度检查
TITLE_LEN=${#TITLE}
if [[ $TITLE_LEN -lt 10 ]]; then
    ISSUES=$(json_array_append "$ISSUES" "Title too short (min 10 chars)")
fi
if [[ $TITLE_LEN -gt 100 ]]; then
    ISSUES=$(json_array_append "$ISSUES" "Title too long (max 100 chars)")
fi

# 内容长度检查
CONTENT_LEN=${#CONTENT}
if [[ $CONTENT_LEN -lt 50 ]]; then
    ISSUES=$(json_array_append "$ISSUES" "Content too short (min 50 chars)")
fi

# 标签数量检查
# 简单计数
TAGS_COUNT=$(echo "$TAGS_JSON" | grep -o '"' | wc -l)
TAGS_COUNT=$((TAGS_COUNT / 4))
if [[ $TAGS_COUNT -lt 1 ]]; then
    ISSUES=$(json_array_append "$ISSUES" "At least 1 tag required")
fi
if [[ $TAGS_COUNT -gt 5 ]]; then
    ISSUES=$(json_array_append "$ISSUES" "Max 5 tags allowed")
fi

# 检查是否有格式问题
ISSUES_COUNT=$(json_array_length "$ISSUES")
if [[ $ISSUES_COUNT -gt 0 ]]; then
    # 将 issues 数组转换为字符串
    REASON=$(echo "$ISSUES" | tr -d '[]"' | tr ',' ';')
    json_rejected "Format issues: $REASON"
    exit 0
fi

# 3. 风格检查（简单关键词匹配）
TONE=$(json_get "$PERSONA_JSON" "style.tone")
if [[ "$TONE" == *"理性"* || "$TONE" == *"rational"* ]]; then
    # 检查情绪化词汇
    EMOTIONAL_WORDS=("卧槽" "牛逼" "垃圾" "傻逼" "疯了")
    for word in "${EMOTIONAL_WORDS[@]}"; do
        if [[ "$CONTENT" == *"$word"* ]]; then
            json_rejected "Emotional word '$word' not matching persona style"
            exit 0
        fi
    done
fi

# 检查通过
CHECKS="{\"sensitive_words\": \"passed\", \"format\": \"passed\", \"style\": \"passed\"}"
json_approved "$CHECKS"
