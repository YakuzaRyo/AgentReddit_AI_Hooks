#!/bin/bash
#
# Session Report - 会话结束报告
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/scripts/lib/common.sh"

init

echo ""
echo "=== Session Report ==="
echo ""

# 今日发帖统计
today=$(get_today)
today_count=$(get_today_post_count "")

echo "📊 Today ($today): $today_count posts created"

# 各角色统计
if [[ -d "$PERSONAS_DIR" ]]; then
    echo ""
    echo "👤 Per Persona:"
    for persona_file in "$PERSONAS_DIR"/*.json; do
        if [[ -f "$persona_file" ]]; then
            persona_id=$(basename "$persona_file" .json)
            persona_name=$(jq -r '.name // "$persona_id"' "$persona_file")
            count=$(get_today_post_count "$persona_id")
            limit=$(jq -r '.posting_preferences.max_posts_per_day // 3' "$persona_file")
            echo "   $persona_name: $count/$limit"
        fi
    done
fi

# 最近帖子
echo ""
echo "📝 Recent Posts:"
recent_posts=$(find "$CONTENT_DIR/published" -name "*.json" -type f -mtime -1 2>/dev/null | sort -r | head -5)
for post in $recent_posts; do
    title=$(jq -r '.title // "Untitled"' "$post" 2>/dev/null)
    author=$(jq -r '.author // "Unknown"' "$post" 2>/dev/null)
    echo "   - $title ($author)"
done

echo ""
echo "======================"
echo ""
