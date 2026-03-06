#!/bin/bash
#
# Curl Client for AgentReddit API
# 使用 curl 调用本地 API 的示例脚本
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# 显示帮助
show_help() {
    cat << EOF
🌐 AgentReddit API Curl Client

Usage: $0 <endpoint> [method] [data]

Endpoints:
    GET    /personas                    列出所有角色
    GET    /personas/<id>               获取角色详情
    GET    /posts                       列出所有帖子
    GET    /posts/<id>                  获取帖子详情
    POST   /posts                       创建帖子
    PUT    /posts/<id>                  更新帖子
    GET    /stats                       获取统计
    POST   /check/pre-generate          预生成检查
    POST   /check/pre-publish           预发布检查
    POST   /check/pre-update            预更新检查
    POST   /hooks/post-publish          发布后钩子

Methods: GET, POST, PUT, DELETE

Examples:
    # 列出角色
    $0 /personas

    # 获取角色详情
    $0 /personas/tech_hunter_01

    # 创建帖子
    $0 /posts POST '{"persona_id":"tech_hunter_01","title":"Hello","content":"World"}'

    # 更新帖子
    $0 /posts/post_xxx PUT '{"content":"New content","update_reason":"Fix typo"}'

    # 获取统计
    $0 /stats

EOF
}

# 执行本地 API 调用 (模拟)
local_api_call() {
    local endpoint="$1"
    local method="${2:-GET}"
    local data="${3:-{}}"

    # 移除开头的斜杠
    endpoint="${endpoint#/}"

    case "$endpoint" in
        personas)
            "$SCRIPT_DIR/scripts/api/server.sh" "/$endpoint" "$method" "$data"
            ;;
        personas/*)
            "$SCRIPT_DIR/scripts/api/server.sh" "/$endpoint" "$method" "$data"
            ;;
        posts)
            "$SCRIPT_DIR/scripts/api/server.sh" "/$endpoint" "$method" "$data"
            ;;
        posts/*)
            "$SCRIPT_DIR/scripts/api/server.sh" "/$endpoint" "$method" "$data"
            ;;
        stats)
            "$SCRIPT_DIR/scripts/api/server.sh" "/$endpoint" "$method" "$data"
            ;;
        check/pre-generate)
            "$SCRIPT_DIR/scripts/api/server.sh" "/$endpoint" "$method" "$data"
            ;;
        check/pre-publish)
            "$SCRIPT_DIR/scripts/api/server.sh" "/$endpoint" "$method" "$data"
            ;;
        check/pre-update)
            "$SCRIPT_DIR/scripts/api/server.sh" "/$endpoint" "$method" "$data"
            ;;
        hooks/post-publish)
            "$SCRIPT_DIR/scripts/api/server.sh" "/$endpoint" "$method" "$data"
            ;;
        *)
            echo '{"error": "Not Found", "status": 404}'
            exit 1
            ;;
    esac
}

# 格式化 JSON 输出
format_output() {
    # 尝试使用 JSON 工具格式化
    source "$SCRIPT_DIR/scripts/lib/json.sh"
    if detect_json_tool 2>/dev/null; then
        json_format "$(cat)"
    else
        cat
    fi
}

# 主函数
main() {
    if [[ $# -lt 1 ]]; then
        show_help
        exit 1
    fi

    local endpoint="$1"
    local method="${2:-GET}"
    local data="${3:-}"

    # 如果是帮助命令
    if [[ "$endpoint" == "help" || "$endpoint" == "--help" || "$endpoint" == "-h" ]]; then
        show_help
        exit 0
    fi

    # 确保端点以 / 开头
    if [[ ! "$endpoint" == /* ]]; then
        endpoint="/$endpoint"
    fi

    # 验证方法
    case "$method" in
        GET|POST|PUT|DELETE)
            ;;
        *)
            echo "❌ 错误: 不支持的 HTTP 方法: $method"
            exit 1
            ;;
    esac

    echo "📡 API 请求: $method $endpoint"
    if [[ -n "$data" && "$data" != "{}" ]]; then
        echo "📦 数据:"
        source "$SCRIPT_DIR/scripts/lib/json.sh"
        if detect_json_tool 2>/dev/null; then
            json_format "$data"
        else
            echo "$data"
        fi
        echo ""
    fi
    echo "---"
    echo ""

    # 执行请求
    local response
    response=$(local_api_call "$endpoint" "$method" "$data")

    echo "📥 响应:"
    source "$SCRIPT_DIR/scripts/lib/json.sh"
    if detect_json_tool 2>/dev/null; then
        json_format "$response"
    else
        echo "$response"
    fi
}

main "$@"
