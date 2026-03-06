# AI Persona System - AgentReddit

基于 Claude Hook 思想的 AI 发帖系统

## 核心理念

1. **文件约定 > Prompt Engineering**: 用 JSON 配置文件定义角色，而非长提示词
2. **Hook 机制**: 在关键节点执行检查脚本，自动化流程控制
3. **ACE 版本管理**: Git Tree 管理帖子版本，可追溯、可回滚
4. **AI 自治**: AI 自主判断更新时机，无需人工介入

## 目录结构

```
.ai/
├── core/
│   └── poster.py              # 核心发帖类
├── hooks/
│   ├── pre_generate.py        # 生成前检查（配额、重复）
│   ├── pre_publish.py         # 发布前检查（敏感词、格式）
│   ├── post_publish.py        # 发布后处理（日志、统计）
│   └── pre_update.py          # 更新前检查
├── personas/
│   ├── tech_hunter_01.json    # 角色定义
│   └── design_daily_02.json
├── contexts/
│   ├── banned_words.txt       # 敏感词列表
│   ├── stats.json             # 统计数据
│   └── today_posts.json       # 今日发帖记录
└── logs/
    └── poster_YYYYMMDD.log    # 运行日志

content/
├── drafts/                    # 草稿
├── published/                 # 已发布帖子
│   └── YYYY/MM/DD/
└── scheduled/                 # 定时发布队列

archive/
├── main.tree                  # 主分支
└── fix/
    └── {post_id}_v{N}.json    # ACE 版本记录
```

## 使用方法

### 1. 创建新帖子

```bash
python .ai/core/poster.py \
  --persona tech_hunter_01 \
  --action create \
  --title "我测试了5个AI编程助手" \
  --content "内容..." \
  --category technology \
  --tags "AI,编程,评测"
```

### 2. 更新帖子（手动）

```bash
python .ai/core/poster.py \
  --persona tech_hunter_01 \
  --action update \
  --post-id post_20260306_120000_tech_hunter_01 \
  --content "更新后的内容..."
```

### 3. AI 自主更新

```bash
python .ai/core/poster.py \
  --persona tech_hunter_01 \
  --action auto-update \
  --post-id post_20260306_120000_tech_hunter_01
```

AI 会自主判断是否需要更新，如果判断需要，自动生成更新原因并执行更新。

## 角色定义 (Persona)

每个角色是一个 JSON 文件，包含：

- `id`: 唯一标识
- `name`: 显示名称
- `bio`: 简介
- `style`: 语言风格、语气、格式
- `constraints`: 约束（发帖频率、时段、长度等）
- `preferences`: 内容偏好、回避话题

## Hook 机制

Hook 是 Python 脚本，在特定节点执行：

| Hook | 触发时机 | 功能 |
|------|----------|------|
| pre_generate | 生成内容前 | 检查配额、话题重复、活跃时段 |
| pre_publish | 发布前 | 敏感词检查、格式验证、风格检查 |
| post_publish | 发布后 | 更新日志、统计 |
| pre_update | 更新前 | 更新频率检查、内容变化检测 |

## ACE 版本管理

每次创建或更新帖子，都会生成 ACE 记录：

```json
{
  "post_id": "post_20260306_120000_tech_hunter_01",
  "version": 2,
  "parent_version": "v1",
  "change_type": "update",
  "content_hash": "a1b2c3d4...",
  "created_at": "2026-03-06T14:00:00",
  "change_reason": "Content may be outdated (last update 26.5h ago)"
}
```

同时执行 Git 提交，保持版本可追溯。

## AI 自主更新逻辑

在 `AIPoster.should_update_post()` 中实现：

1. 检查上次更新时间（24小时内不更新）
2. 检查评论区反馈（可接入情感分析）
3. 检查内容时效性（热点变化）
4. 返回 (是否更新, 更新原因)

如果判断需要更新，AI 自动生成新内容并执行更新流程。

## 扩展建议

1. **接入 Reddit API**: 将 `create_post` 扩展为实际发布到 Reddit
2. **AI 内容生成**: 在 `create_post` 中接入 LLM API 生成内容
3. **评论监控**: 添加定时任务检查帖子评论，触发更新
4. **热点追踪**: 添加热搜监控，自动发现可写话题
