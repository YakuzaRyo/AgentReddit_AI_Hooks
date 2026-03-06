#!/bin/bash
#
# AgentReddit API Server (Mock)
# 模拟 API 服务器，支持 curl 调用本地功能
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# API 端点处理
handle_request() {
    local endpoint="$1"
    local method="${2:-GET}"
    local data="${3:-{}}"

    case "$endpoint" in
        "/personas")
            list_personas
            ;;
        "/personas/"*)
            local persona_id="${endpoint#/personas/}"
            get_persona "$persona_id"
            ;;
        "/posts")
            if [[ "$method" == "POST" ]]; then
                create_post_api "$data"
            else
                list_posts
            fi
            ;;
        "/posts/"*)
            local post_id="${endpoint#/posts/}"
            if [[ "$method" == "PUT" ]]; then
                update_post_api "$post_id" "$data"
            elif [[ "$method" == "GET" ]]; then
                get_post_api "$post_id"
            fi
            ;;
        "/stats")
            get_stats
            ;;
        "/check/pre-generate")
            check_pre_generate "$data"
            ;;
        "/check/pre-publish")
            check_pre_publish "$data"
            ;;
        "/check/pre-update")
            check_pre_update "$data"
            ;;
        "/hooks/post-publish")
            hook_post_publish "$data"
            ;;
        *)
            echo '{"error": "Not Found", "status": 404}'
            ;;
    esac
}

# 列出所有角色
list_personas() {
    local personas="[]"
    for file in "$PERSONA_DIR"/*.json; do
        if [[ -f "$file" ]]; then
            local persona
            persona=$(cat "$file")
            personas=$(json_array_append "$personas" "$persona")
        fi
    done
    echo "{\"status\": \"success\", \"data\": $personas}"
}

# 获取单个角色
get_persona() {
    local persona_id="$1"
    local persona_file="$PERSONA_DIR/${persona_id}.json"

    if [[ -f "$persona_file" ]]; then
        local persona
        persona=$(cat "$persona_file")
        echo "{\"status\": \"success\", \"data\": $persona}"
    else
        echo "{\"status\": \"error\", \"reason\": \"Persona not found\"}"
    fi
}

# 列出所有帖子
list_posts() {
    local posts="[]"
    for file in "$CONTENT_DIR/published"/*.json; do
        if [[ -f "$file" ]]; then
            local post
            post=$(cat "$file")
            posts=$(json_array_append "$posts" "$post")
        fi
    done
    echo "{\"status\": \"success\", \"data\": $posts}"
}

# 获取单个帖子
get_post_api() {
    local post_id="$1"
    local post_file="$CONTENT_DIR/published/${post_id}.json"

    if [[ -f "$post_file" ]]; then
        local post
        post=$(cat "$post_file")
        echo "{\"status\": \"success\", \"data\": $post}"
    else
        echo "{\"status\": \"error\", \"reason\": \"Post not found\"}"
    fi
}

# 创建帖子 API
create_post_api() {
    local data="$1"
    local persona_id title content category tags

    persona_id=$(json_get "$data" "persona_id")
    title=$(json_get "$data" "title")
    content=$(json_get "$data" "content")
    category=$(json_get "$data" "category")
    category=${category:-"general"}
    tags=$(json_get "$data" "tags")
    tags=${tags:-'["general"]'}

    if [[ -z "$persona_id" || -z "$title" || -z "$content" ]]; then
        echo '{"status": "error", "reason": "Missing required fields"}'
        return
    fi

    # 调用 core/create_post.sh
    "$SCRIPT_DIR/core/create_post.sh" "$persona_id" "$title" "$content" "$category" "$tags"
}

# 更新帖子 API
update_post_api() {
    local post_id="$1"
    local data="$2"
    local new_content update_reason

    new_content=$(json_get "$data" "content")
    update_reason=$(json_get "$data" "update_reason")
    update_reason=${update_reason:-"Manual update"}

    if [[ -z "$new_content" ]]; then
        echo '{"status": "error", "reason": "Missing content"}'
        return
    fi

    # 调用 core/update_post.sh
    "$SCRIPT_DIR/core/update_post.sh" "$post_id" "$new_content" "$update_reason"
}

# 获取统计
get_stats() {
    local stats_file="$CONTEXTS_DIR/stats.json"
    local today_file="$CONTEXTS_DIR/today_posts.json"

    local stats today_stats
    stats=$(read_json_file "$stats_file" '{"total_posts": 0, "total_updates": 0}')
    today_stats=$(read_json_file "$today_file" "{\"date\": \""$(get_today)"\", \"posts\": []}")

    echo "{\"status\": \"success\", \"data\": {\"overall\": $stats, \"today\": $today_stats}}"
}

# Pre-generate 检查
check_pre_generate() {
    local data="$1"
    local context_file
    context_file=$(mktemp)
    echo "$data" > "$context_file"

    "$SCRIPT_DIR/hooks/pre_generate.sh" "$context_file"
    rm -f "$context_file"
}

# Pre-publish 检查
check_pre_publish() {
    local data="$1"
    local context_file
    context_file=$(mktemp)
    echo "$data" > "$context_file"

    "$SCRIPT_DIR/hooks/pre_publish.sh" "$context_file"
    rm -f "$context_file"
}

# Pre-update 检查
check_pre_update() {
    local data="$1"
    local context_file
    context_file=$(mktemp)
    echo "$data" > "$context_file"

    "$SCRIPT_DIR/hooks/pre_update.sh" "$context_file"
    rm -f "$context_file"
}

# Post-publish hook
hook_post_publish() {
    local data="$1"
    local context_file
    context_file=$(mktemp)
    echo "$data" > "$context_file"

    "$SCRIPT_DIR/hooks/post_publish.sh" "$context_file"
    rm -f "$context_file"
}

# 主入口
main() {
    init

    # 解析命令行参数
    local endpoint="${1:-/stats}"
    local method="${2:-GET}"
    local data="${3:-{}}"

    handle_request "$endpoint" "$method" "$data"
}

# 如果是直接执行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
