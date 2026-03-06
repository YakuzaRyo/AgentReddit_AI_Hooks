#!/bin/bash
#
# SessionStart Hook - AI Persona System Initialization (Bash Version)
# 在会话开始时执行初始化检查和状态汇报
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

init

# 获取可用角色列表
get_available_personas() {
    local personas="[]"

    for file in "$PERSONA_DIR"/*.json; do
        if [[ -f "$file" ]]; then
            local id name avatar bio
            id=$(json_get "$(cat "$file")" "id")
            name=$(json_get "$(cat "$file")" "name")
            avatar=$(json_get "$(cat "$file")" "avatar")
            bio=$(json_get "$(cat "$file")" "bio")

            name=${name:-"Unknown"}
            avatar=${avatar:-"🤖"}
            bio=${bio:-""}
            bio=$(echo "$bio" | cut -c1-50)

            if [[ -n "$id" ]]; then
                local persona_entry
                persona_entry="{\"id\": \"$id\", \"name\": \"$name\", \"avatar\": \"$avatar\", \"bio\": \"$bio\"}"
                personas=$(json_array_append "$personas" "$persona_entry")
            fi
        fi
    done

    echo "$personas"
}

# 获取今日发帖统计
get_today_stats() {
    local today
    today=$(get_today)
    local today_file="$CONTEXTS_DIR/today_posts.json"

    local data
    data=$(read_json_file "$today_file" "{\"date\": \"$today\", \"posts\": []}")

    local file_date
    file_date=$(json_get "$data" "date")

    if [[ "$file_date" != "$today" ]]; then
        echo "{\"date\": \"$today\", \"count\": 0, \"posts\": []}"
    else
        local posts_list
        posts_list=$(json_get "$data" "posts")
        local count
        count=$(json_array_length "$posts_list")
        echo "{\"date\": \"$today\", \"count\": $count, \"posts\": $posts_list}"
    fi
}

# 检查定时发布队列
check_scheduled_posts() {
    local scheduled="[]"
    local scheduled_dir="$CONTENT_DIR/scheduled"

    if [[ -d "$scheduled_dir" ]]; then
        for file in "$scheduled_dir"/*.json; do
            if [[ -f "$file" ]]; then
                local id title scheduled_time
                id=$(basename "$file" .json)
                title=$(json_get "$(cat "$file")" "title")
                scheduled_time=$(json_get "$(cat "$file")" "scheduled_time")

                title=${title:-"Untitled"}
                scheduled_time=${scheduled_time:-"unknown"}

                local entry
                entry="{\"id\": \"$id\", \"title\": \"$title\", \"scheduled_time\": \"$scheduled_time\"}"
                scheduled=$(json_array_append "$scheduled" "$entry")
            fi
        done
    fi

    echo "$scheduled"
}

# 检查草稿箱
check_drafts() {
    local drafts="[]"
    local drafts_dir="$CONTENT_DIR/drafts"

    if [[ -d "$drafts_dir" ]]; then
        for file in "$drafts_dir"/*.md; do
            if [[ -f "$file" ]]; then
                local id title
                id=$(basename "$file" .md)
                title=$(echo "$id" | tr '_' ' ' | sed 's/.*/\L&/; s/[a-z]*/\u&/g')

                local entry
                entry="{\"id\": \"$id\", \"title\": \"$title\"}"
                drafts=$(json_array_append "$drafts" "$entry")
            fi
        done
    fi

    echo "$drafts"
}

# 主函数
main() {
    echo "🚀 AgentReddit AI Persona System"
    echo "======================================"

    # 1. 检查可用角色
    local personas
    personas=$(get_available_personas)
    local persona_count
    persona_count=$(json_array_length "$personas")

    echo ""
    echo "📋 可用角色 (${persona_count}个):"

    # 遍历输出角色信息
    local i=0
    while [[ $i -lt $persona_count ]]; do
        local p
        p=$(json_get "$personas" "$i")
        local name avatar id bio
        name=$(json_get "$p" "name")
        avatar=$(json_get "$p" "avatar")
        id=$(json_get "$p" "id")
        bio=$(json_get "$p" "bio")
        echo "   $avatar $name ($id)"
        echo "      └─ $bio..."
        i=$((i + 1))
    done

    # 2. 今日发帖统计
    local stats
    stats=$(get_today_stats)
    local today_date today_count
    today_date=$(json_get "$stats" "date")
    today_count=$(json_get "$stats" "count")

    echo ""
    echo "📊 今日发帖统计 ($today_date):"
    echo "   已发布: $today_count 篇"

    # 3. 检查定时队列
    local scheduled
    scheduled=$(check_scheduled_posts)
    local scheduled_count
    scheduled_count=$(json_array_length "$scheduled")

    echo ""
    echo "⏰ 定时发布队列: $scheduled_count 篇"

    i=0
    while [[ $i -lt $scheduled_count && $i -lt 3 ]]; do
        local s
        s=$(json_get "$scheduled" "$i")
        local title sched_time
        title=$(json_get "$s" "title")
        sched_time=$(json_get "$s" "scheduled_time")
        echo "   • $title @ $sched_time"
        i=$((i + 1))
    done

    # 4. 检查草稿
    local drafts
    drafts=$(check_drafts)
    local drafts_count
    drafts_count=$(json_array_length "$drafts")

    echo ""
    echo "📝 草稿箱: $drafts_count 篇"

    i=0
    while [[ $i -lt $drafts_count && $i -lt 3 ]]; do
        local d
        d=$(json_get "$drafts" "$i")
        local title
        title=$(json_get "$d" "title")
        echo "   • $title"
        i=$((i + 1))
    done

    # 5. 建议操作
    echo ""
    echo "💡 建议操作:"
    if [[ $scheduled_count -gt 0 ]]; then
        echo "   1. 执行定时发布队列中的任务"
    fi
    if [[ $drafts_count -gt 0 ]]; then
        local num=$(( scheduled_count > 0 ? 2 : 1 ))
        echo "   $num. 完善草稿箱中的 $drafts_count 篇内容"
    fi
    if [[ $scheduled_count -eq 0 && $drafts_count -eq 0 ]]; then
        echo "   1. 创建新的话题内容"
    fi
    echo "   • 使用 --persona <id> 指定角色"
    echo "   • 使用 --action create/update/auto-update 执行操作"

    echo ""
    echo "======================================"
    echo "✅ 初始化完成，AI Persona 已就绪"

    # 保存上下文供后续使用
    # 构建角色 ID 列表
    local persona_ids="["
    i=0
    while [[ $i -lt $persona_count ]]; do
        if [[ $i -gt 0 ]]; then
            persona_ids+=", "
        fi
        local p
        p=$(json_get "$personas" "$i")
        local id
        id=$(json_get "$p" "id")
        persona_ids+="\"$id\""
        i=$((i + 1))
    done
    persona_ids+="]"

    local context
    context="{\"available_personas\": $persona_ids, \"today_post_count\": $today_count, \"scheduled_count\": $scheduled_count, \"draft_count\": $drafts_count}"

    write_json_file "$CONTEXTS_DIR/session_context.json" "$context"
}

# 执行主函数
main
