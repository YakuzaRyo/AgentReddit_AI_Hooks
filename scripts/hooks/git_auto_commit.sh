#!/bin/bash
#
# Git Auto Commit - 自动提交更改到 Git
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$SCRIPT_DIR"

# 检查是否在 git 仓库
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Not a git repository"
    exit 0
fi

# 检查是否有更改
if git diff --quiet && git diff --cached --quiet; then
    echo "No changes to commit"
    exit 0
fi

# 获取更改的文件列表
changed_files=$(git diff --name-only)
staged_files=$(git diff --cached --name-only)
all_files="${changed_files}${staged_files}"

# 生成提交信息
if [[ -n "$staged_files" ]]; then
    file_count=$(echo "$staged_files" | wc -l)
else
    file_count=$(echo "$changed_files" | wc -l)
fi

if [[ "$file_count" -eq 1 ]]; then
    filename=$(basename "$all_files" | head -1)
    commit_msg="[Atomic] Update $filename"
else
    commit_msg="[Atomic] Update $file_count files"
fi

# 添加并提交
git add -A
git commit -m "$commit_msg" --quiet

if [[ $? -eq 0 ]]; then
    hash=$(git rev-parse --short HEAD)
    echo "[git] Committed: $hash - $commit_msg"
else
    echo "[git] Commit failed"
fi
