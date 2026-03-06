#!/bin/bash
#
# Skill Eval Wrapper - 技能评估包装器
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# 检查 .claude/skills/ 目录下的技能
evaluate_skills() {
    local skills_dir="$SCRIPT_DIR/.claude/skills"
    
    if [[ ! -d "$skills_dir" ]]; then
        exit 0
    fi
    
    # 检查每个技能的 evals
    for skill_dir in "$skills_dir"/*/; do
        if [[ -d "$skill_dir" ]]; then
            local eval_file="$skill_dir/evals/evals.json"
            if [[ -f "$eval_file" ]]; then
                skill_name=$(basename "$skill_dir")
                echo "[skill] Loaded: $skill_name"
            fi
        fi
    done
}

evaluate_skills
exit 0
