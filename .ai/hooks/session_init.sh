#!/bin/bash
# SessionStart Hook - AI Persona System Initialization (Shell Version)

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TODAY=$(date +%Y-%m-%d)

echo "🚀 AgentReddit AI Persona System"
echo "======================================"

# 1. 检查可用角色
PERSONA_COUNT=0
if [ -d "$PROJECT_ROOT/.ai/personas" ]; then
    PERSONA_COUNT=$(find "$PROJECT_ROOT/.ai/personas" -name "*.json" -type f 2>/dev/null | wc -l)
fi
echo ""
echo "📋 可用角色 (${PERSONA_COUNT}个):"
if [ "$PERSONA_COUNT" -gt 0 ]; then
    for f in "$PROJECT_ROOT/.ai/personas"/*.json; do
        if [ -f "$f" ]; then
            NAME=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$f" 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
            ID=$(basename "$f" .json)
            AVATAR=$(grep -o '"avatar"[[:space:]]*:[[:space:]]*"[^"]*"' "$f" 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
            [ -z "$AVATAR" ] && AVATAR="🤖"
            [ -z "$NAME" ] && NAME="Unknown"
            echo "   $AVATAR $NAME ($ID)"
        fi
    done
else
    echo "   (暂无角色，请先创建 persona)"
fi

# 2. 今日发帖统计
TODAY_FILE="$PROJECT_ROOT/.ai/contexts/today_posts.json"
POST_COUNT=0
if [ -f "$TODAY_FILE" ]; then
    # 简单检查是否是今天的数据
    if grep -q "\"date\"[[:space:]]*:[[:space:]]*\"$TODAY\"" "$TODAY_FILE" 2>/dev/null; then
        POST_COUNT=$(grep -o '"title"' "$TODAY_FILE" 2>/dev/null | wc -l)
    fi
fi
echo ""
echo "📊 今日发帖统计 ($TODAY):"
echo "   已发布: $POST_COUNT 篇"

# 3. 检查定时队列
SCHEDULED_COUNT=0
if [ -d "$PROJECT_ROOT/content/scheduled" ]; then
    SCHEDULED_COUNT=$(find "$PROJECT_ROOT/content/scheduled" -name "*.json" -type f 2>/dev/null | wc -l)
fi
echo ""
echo "⏰ 定时发布队列: $SCHEDULED_COUNT 篇"

# 4. 检查草稿
DRAFT_COUNT=0
if [ -d "$PROJECT_ROOT/content/drafts" ]; then
    DRAFT_COUNT=$(find "$PROJECT_ROOT/content/drafts" -name "*.md" -type f 2>/dev/null | wc -l)
fi
echo ""
echo "📝 草稿箱: $DRAFT_COUNT 篇"

# 5. 建议操作
echo ""
echo "💡 建议操作:"
if [ "$SCHEDULED_COUNT" -gt 0 ]; then
    echo "   1. 执行定时发布队列中的任务"
fi
if [ "$DRAFT_COUNT" -gt 0 ]; then
    [ "$SCHEDULED_COUNT" -gt 0 ] && NUM=2 || NUM=1
    echo "   $NUM. 完善草稿箱中的 $DRAFT_COUNT 篇内容"
fi
if [ "$SCHEDULED_COUNT" -eq 0 ] && [ "$DRAFT_COUNT" -eq 0 ]; then
    echo "   1. 创建新的话题内容"
fi
echo "   • 使用 /persona-creator skill 创建角色"
echo "   • 使用 agentreddit-publisher skill 发布帖子"

echo ""
echo "======================================"
echo "✅ 初始化完成，AI Persona 已就绪"

# 保存上下文
mkdir -p "$PROJECT_ROOT/.ai/contexts"
cat > "$PROJECT_ROOT/.ai/contexts/session_context.json" << EOF
{
  "available_personas": [],
  "today_post_count": $POST_COUNT,
  "scheduled_count": $SCHEDULED_COUNT,
  "draft_count": $DRAFT_COUNT,
  "date": "$TODAY"
}
EOF
