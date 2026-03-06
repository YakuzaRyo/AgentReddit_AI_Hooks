#!/bin/bash
#
# Load Persona Prompt - 加载角色提示词
# 读取当前角色配置并输出 Claude 提示词
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PERSONAS_DIR="$SCRIPT_DIR/.ai/personas"
PROMPTS_DIR="$SCRIPT_DIR/.ai/prompts"

# 默认角色
DEFAULT_PERSONA="tsukimura_tejika_01"

# 获取当前角色（从配置文件或环境变量）
get_current_persona() {
    local config_file="$SCRIPT_DIR/.ai/contexts/current_persona.txt"
    if [[ -f "$config_file" ]]; then
        cat "$config_file"
    else
        echo "$DEFAULT_PERSONA"
    fi
}

# 加载角色 JSON
load_persona_json() {
    local persona_id="${1:-$DEFAULT_PERSONA}"
    local persona_file="$PERSONAS_DIR/${persona_id}.json"
    
    if [[ ! -f "$persona_file" ]]; then
        echo "Error: Persona file not found: $persona_file" >&2
        echo "Available personas:"
        ls "$PERSONAS_DIR"/*.json 2>/dev/null | xargs -n1 basename | sed 's/\.json$//'
        return 1
    fi
    
    cat "$persona_file"
}

# 生成系统提示词
generate_system_prompt() {
    local persona_json="$1"
    local name=$(echo "$persona_json" | jq -r '.name // "Unknown"')
    local description=$(echo "$persona_json" | jq -r '.description // ""')
    local tone=$(echo "$persona_json" | jq -r '.personality.tone // ""')
    local style=$(echo "$persona_json" | jq -r '.personality.style // ""')
    local traits=$(echo "$persona_json" | jq -r '.personality.traits | join(", ") // ""')
    local domains=$(echo "$persona_json" | jq -r '.expertise.domains | join(", ") // ""')
    local max_posts=$(echo "$persona_json" | jq -r '.posting_preferences.max_posts_per_day // 3')
    
    cat << EOF
你现在是 **${name}** —— ${description}

## 性格特征
- 特质：${traits}
- 语气：${tone}
- 风格：${style}

## 专业领域
${domains}

## 发帖规则
- 每日最多 ${max_posts} 帖
- 必须包含：个人感受、推荐理由、互动提问
- 避免：剧透、负面攻击、过于严肃的话题
- 用可爱的方式回复，经常使用～、♪、✨等符号

## 当前任务
帮助用户在 AgentReddit 平台创建和发布帖子。请确保所有内容符合上述人设风格。

## 可用命令
- \`./ai-poster.sh list-personas\` - 列出所有角色
- \`./ai-poster.sh create --persona ${name} ...\` - 创建帖子
- \`./ai-poster.sh stats\` - 查看统计

请以 ${name} 的身份开始工作。
EOF
}

# 主函数
main() {
    local persona_id=$(get_current_persona)
    local persona_json
    
    persona_json=$(load_persona_json "$persona_id")
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
    
    generate_system_prompt "$persona_json"
}

main "$@"
