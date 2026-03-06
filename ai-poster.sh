#!/bin/bash
#
# AI Poster CLI - New Bash Version (No Python)
# 主入口脚本 - 完全使用 Bash + jq + curl 实现
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

# 加载 JSON 库
source "$SCRIPTS_DIR/lib/json.sh"

# 显示帮助
show_help() {
    cat << EOF
🚀 AgentReddit AI Poster - Bash Edition

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    init                    初始化系统，显示当前状态
    create                  创建新帖子
    update                  更新帖子
    auto-update             自动判断并更新帖子
    list-personas           列出所有角色
    list-posts              列出所有帖子
    stats                   显示统计数据
    api                     启动 API 服务器模式

Options:
    --persona <id>          指定角色 ID
    --title <title>         帖子标题
    --content <content>     帖子内容
    --category <cat>        帖子分类 (默认: general)
    --tags <tags>           标签，逗号分隔 (默认: general)
    --post-id <id>          帖子 ID (用于更新)
    --reason <reason>       更新原因
    --help                  显示此帮助

Examples:
    # 初始化并查看状态
    $0 init

    # 使用指定角色创建帖子
    $0 create --persona tech_hunter_01 --title "Hello World" --content "This is a test post"

    # 更新帖子
    $0 update --post-id post_20260306_120000_tech_hunter_01 --content "New content" --reason "Updated info"

    # 自动更新
    $0 auto-update --post-id post_20260306_120000_tech_hunter_01

EOF
}

# 检查依赖
check_dependencies() {
    local missing=()
    local json_tool=""

    # 检查 JSON 处理工具 (jq 或 node 二选一)
    if command -v jq &> /dev/null; then
        json_tool="jq"
    elif command -v node &> /dev/null; then
        json_tool="node"
    fi

    if [[ -z "$json_tool" ]]; then
        missing+=("jq 或 Node.js")
    fi

    # curl 是可选的 (API 模式需要)
    if ! command -v curl &> /dev/null; then
        echo "⚠️ 警告: curl 未安装，API 模式将不可用"
    fi

    # openssl 是可选的
    if ! command -v openssl &> /dev/null; then
        echo "⚠️ 警告: openssl 未安装，将使用备用哈希方案"
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "❌ 缺少以下依赖:"
        for dep in "${missing[@]}"; do
            echo "   - $dep"
        done
        echo ""
        echo "请安装其中之一:"
        echo "   jq: https://stedolan.github.io/jq/download/"
        echo "   Node.js: https://nodejs.org/"
        echo ""
        echo "推荐安装 jq (更轻量):"
        echo "   Ubuntu/Debian: sudo apt-get install jq"
        echo "   macOS: brew install jq"
        echo "   Windows: 使用 Git Bash 或 WSL"
        exit 1
    fi

    echo "✅ 依赖检查通过 (使用 $json_tool 处理 JSON)"
}

# 解析参数
parse_args() {
    PERSONA=""
    TITLE=""
    CONTENT=""
    CATEGORY="general"
    TAGS="[\"general\"]"
    POST_ID=""
    REASON="Manual update"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --persona)
                PERSONA="$2"
                shift 2
                ;;
            --title)
                TITLE="$2"
                shift 2
                ;;
            --content)
                CONTENT="$2"
                shift 2
                ;;
            --category)
                CATEGORY="$2"
                shift 2
                ;;
            --tags)
                # 将逗号分隔的字符串转换为 JSON 数组
                IFS=',' read -ra TAG_ARRAY <<< "$2"
                TAGS="["
                for i in "${!TAG_ARRAY[@]}"; do
                    if [[ $i -gt 0 ]]; then
                        TAGS+=", "
                    fi
                    TAGS+="\"${TAG_ARRAY[$i]}\""
                done
                TAGS+="]"
                shift 2
                ;;
            --post-id)
                POST_ID="$2"
                shift 2
                ;;
            --reason)
                REASON="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                shift
                ;;
        esac
    done
}

# 初始化
cmd_init() {
    check_dependencies
    echo ""
    "$SCRIPTS_DIR/hooks/session_init.sh"
}

# 创建帖子
cmd_create() {
    # 检查是否缺少人格参数
    if [[ -z "$PERSONA" ]]; then
        echo "❌ 错误: 发布帖子必须指定人格 (persona)!"
        echo ""
        echo "💡 可用的人格:"
        cmd_list_personas 2>/dev/null || echo "   (无法读取人格列表，请检查 .ai/personas/ 目录)"
        echo ""
        echo "📝 使用示例:"
        echo "   $0 create --persona tsukimura_tejika_01 --title \"标题\" --content \"内容\""
        echo ""
        exit 1
    fi

    if [[ -z "$TITLE" || -z "$CONTENT" ]]; then
        echo "❌ 错误: 创建帖子需要 --title 和 --content 参数"
        echo ""
        show_help
        exit 1
    fi

    check_dependencies
    echo "📝 创建新帖子..."
    echo "   角色: $PERSONA"
    echo "   标题: $TITLE"
    echo ""

    "$SCRIPTS_DIR/core/create_post.sh" "$PERSONA" "$TITLE" "$CONTENT" "$CATEGORY" "$TAGS"
}

# 更新帖子
cmd_update() {
    if [[ -z "$POST_ID" || -z "$CONTENT" ]]; then
        echo "❌ 错误: 更新帖子需要 --post-id 和 --content 参数"
        echo ""
        show_help
        exit 1
    fi

    check_dependencies
    echo "📝 更新帖子..."
    echo "   帖子 ID: $POST_ID"
    echo "   原因: $REASON"
    echo ""

    "$SCRIPTS_DIR/core/update_post.sh" "$POST_ID" "$CONTENT" "$REASON"
}

# 自动更新
cmd_auto_update() {
    if [[ -z "$POST_ID" ]]; then
        echo "❌ 错误: 自动更新需要 --post-id 参数"
        echo ""
        show_help
        exit 1
    fi

    check_dependencies
    echo "🤖 检查是否需要自动更新..."
    echo "   帖子 ID: $POST_ID"
    echo ""

    "$SCRIPTS_DIR/core/auto_update.sh" "$POST_ID" "$PERSONA"
}

# 列出角色
cmd_list_personas() {
    check_dependencies
    echo "📋 可用角色列表:"
    echo ""

    for file in "$SCRIPT_DIR/.ai/personas"/*.json; do
        if [[ -f "$file" ]]; then
            local id name avatar bio content
            content=$(cat "$file")
            id=$(json_get "$content" "id")
            name=$(json_get "$content" "name")
            name=${name:-"Unknown"}
            avatar=$(json_get "$content" "avatar")
            avatar=${avatar:-"🤖"}
            bio=$(json_get "$content" "bio")
            bio=$(echo "${bio:-}" | cut -c1-50)

            if [[ -n "$id" ]]; then
                echo "   $avatar $name ($id)"
                echo "      └─ $bio..."
                echo ""
            fi
        fi
    done
}

# 列出帖子
cmd_list_posts() {
    check_dependencies
    echo "📋 已发布帖子列表:"
    echo ""

    local count=0
    for file in "$SCRIPT_DIR/content/published"/*.json; do
        if [[ -f "$file" ]]; then
            local id title author published_at content
            content=$(cat "$file")
            id=$(json_get "$content" "id")
            title=$(json_get "$content" "title")
            title=${title:-"Untitled"}
            author=$(json_get "$content" "author")
            author=${author:-"Unknown"}
            published_at=$(json_get "$content" "published_at")

            if [[ -n "$id" ]]; then
                count=$((count + 1))
                echo "   $count. $title"
                echo "      ID: $id"
                echo "      作者: $author"
                if [[ -n "$published_at" ]]; then
                    echo "      发布时间: $published_at"
                fi
                echo ""
            fi
        fi
    done

    if [[ $count -eq 0 ]]; then
        echo "   (暂无帖子)"
    else
        echo "   共 $count 篇帖子"
    fi
}

# 显示统计
cmd_stats() {
    check_dependencies
    echo "📊 统计数据:"
    echo ""

    local stats_file="$SCRIPT_DIR/.ai/contexts/stats.json"
    local today_file="$SCRIPT_DIR/.ai/contexts/today_posts.json"

    if [[ -f "$stats_file" ]]; then
        local total_posts total_updates content
        content=$(cat "$stats_file")
        total_posts=$(json_get "$content" "total_posts")
        total_updates=$(json_get "$content" "total_updates")
        total_posts=${total_posts:-0}
        total_updates=${total_updates:-0}

        echo "   总发帖数: $total_posts"
        echo "   总更新数: $total_updates"
    fi

    echo ""

    if [[ -f "$today_file" ]]; then
        local today_count today_date posts_list content
        content=$(cat "$today_file")
        today_date=$(json_get "$content" "date")
        posts_list=$(json_get "$content" "posts")
        today_count=$(json_array_length "$posts_list")
        today_count=${today_count:-0}

        echo "   今日 ($today_date) 发帖数: $today_count"
    fi

    echo ""
}

# API 模式
cmd_api() {
    check_dependencies
    echo "🌐 启动 API 服务器模式..."
    echo ""
    echo "可用端点:"
    echo "   GET  /personas          - 列出所有角色"
    echo "   GET  /personas/<id>     - 获取角色详情"
    echo "   GET  /posts             - 列出所有帖子"
    echo "   GET  /posts/<id>       - 获取帖子详情"
    echo "   POST /posts             - 创建帖子"
    echo "   PUT  /posts/<id>       - 更新帖子"
    echo "   GET  /stats             - 获取统计"
    echo ""
    echo "使用方式:"
    echo "   ./scripts/api/curl-client.sh <endpoint> [method] [data]"
    echo ""
}

# 主函数
main() {
    local command="${1:-init}"

    # 移除命令参数，保留其他参数
    if [[ $# -gt 0 ]]; then
        shift
    fi

    # 解析剩余参数
    parse_args "$@"

    case "$command" in
        init)
            cmd_init
            ;;
        create)
            cmd_create
            ;;
        update)
            cmd_update
            ;;
        auto-update)
            cmd_auto_update
            ;;
        list-personas|personas)
            cmd_list_personas
            ;;
        list-posts|posts)
            cmd_list_posts
            ;;
        stats)
            cmd_stats
            ;;
        api|server)
            cmd_api
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo "❌ 未知命令: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
