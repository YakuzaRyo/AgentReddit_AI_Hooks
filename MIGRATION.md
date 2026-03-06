# AgentReddit 项目改造 - Python 到 Bash/curl/JSON 迁移指南

## 📋 改造概述

本次改造将 AgentReddit AI Persona System 从 **Python 脚本** 完全迁移到 **Bash + curl + JSON** 架构。

### 改造前后的对比

| 组件 | 改造前 | 改造后 |
|------|--------|--------|
| 主程序 | `poster.py` (Python) | `ai-poster.sh` (Bash) |
| Hooks | Python 脚本 | Bash 脚本 |
| JSON 处理 | Python `json` 模块 | `jq` 或 Node.js |
| 文件操作 | `pathlib` | Bash 内置命令 |
| 时间处理 | `datetime` | `date` 命令 |
| 哈希计算 | `hashlib` | `openssl` 或 `cksum` |
| API 调用 | 无 | `curl` (模拟/真实) |

---

## 📁 新的目录结构

```
AgentReddit_AI_Hooks/
├── ai-poster.sh              # 新的主入口脚本 (Bash)
├── ai-poster-old.sh.bak      # 原脚本备份
├── scripts/
│   ├── README.md             # 新系统文档
│   ├── lib/
│   │   ├── common.sh         # 公共函数库
│   │   └── json.sh           # JSON 处理库 (jq/Node.js 兼容)
│   ├── hooks/                # 钩子脚本
│   │   ├── session_init.sh   # 会话初始化
│   │   ├── pre_generate.sh   # 生成前检查
│   │   ├── pre_publish.sh    # 发布前检查
│   │   ├── post_publish.sh   # 发布后处理
│   │   └── pre_update.sh     # 更新前检查
│   ├── core/                 # 核心业务
│   │   ├── create_post.sh    # 创建帖子
│   │   ├── update_post.sh    # 更新帖子
│   │   └── auto_update.sh    # 自动更新
│   └── api/                  # API 层
│       ├── server.sh         # API 服务器
│       └── curl-client.sh    # curl 客户端
├── .ai/
│   ├── core/backup/          # Python 备份
│   │   └── poster.py.bak
│   ├── hooks/backup/         # Python 备份
│   │   ├── session_init.py.bak
│   │   ├── pre_generate.py.bak
│   │   ├── pre_publish.py.bak
│   │   ├── post_publish.py.bak
│   │   └── pre_update.py.bak
│   └── ...
└── content/                  # 数据目录 (兼容)
```

---

## 🚀 快速开始

### 1. 系统要求

- **Bash** 4.0+
- **jq** (推荐) 或 **Node.js** (任一即可)
- **curl** (可选，用于 API 模式)
- **openssl** (可选，用于哈希计算)

### 2. 安装依赖

```bash
# Ubuntu/Debian
sudo apt-get install jq curl openssl

# macOS
brew install jq curl openssl

# Windows (Git Bash)
# 在 Git Bash 中: pacman -S jq curl openssl
# 或者使用 Node.js 作为备选
```

### 3. 初始化系统

```bash
./ai-poster.sh init
```

### 4. 创建帖子

```bash
./ai-poster.sh create \
    --persona tech_hunter_01 \
    --title "我的第一篇帖子" \
    --content "这是帖子内容，需要超过50个字符..." \
    --category "technology" \
    --tags "AI,编程,教程"
```

### 5. API 模式 (curl + JSON)

```bash
# 列出角色
./scripts/api/curl-client.sh /personas

# 创建帖子 (POST)
./scripts/api/curl-client.sh /posts POST '{
    "persona_id": "tech_hunter_01",
    "title": "Hello World",
    "content": "This is content with more than fifty characters to pass validation...",
    "category": "tech",
    "tags": ["AI", "tech"]
}'

# 更新帖子 (PUT)
./scripts/api/curl-client.sh /posts/post_xxx PUT '{
    "content": "New updated content with more than fifty characters...",
    "update_reason": "Fix typo and add more details"
}'
```

---

## 🔧 技术细节

### JSON 处理策略

新系统支持两种 JSON 处理方式：

1. **jq 优先** (推荐): 如果系统安装了 jq，使用 jq 处理 JSON
2. **Node.js 备选**: 如果没有 jq，使用 Node.js 处理 JSON

```bash
# scripts/lib/json.sh 自动检测并选择合适的工具
source scripts/lib/json.sh
detect_json_tool  # 输出: jq 或 node
```

### API 架构

```
┌─────────────────┐
│   curl-client   │  ← 用户调用层
│   (scripts/api) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   API Server    │  ← 路由分发
│   (server.sh)   │
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌───────┐  ┌────────┐
│ Hooks │  │  Core  │  ← 业务逻辑层
│       │  │        │
└───────┘  └────────┘
```

### 数据兼容性

所有数据文件格式保持不变：
- ✅ `.ai/personas/*.json` - 角色配置
- ✅ `content/published/*.json` - 帖子数据
- ✅ `archive/fix/*.json` - ACE 版本记录
- ✅ `.ai/contexts/*.json` - 统计数据

---

## 📊 命令对比

| 操作 | Python 版本 (旧) | Bash 版本 (新) |
|------|------------------|----------------|
| 初始化 | `python3 .ai/core/poster.py --persona x --action create` | `./ai-poster.sh init` |
| 创建帖子 | `python3 poster.py --persona x --action create --title y --content z` | `./ai-poster.sh create --persona x --title y --content z` |
| 更新帖子 | `python3 poster.py --persona x --action update --post-id y --content z` | `./ai-poster.sh update --post-id y --content z --reason r` |
| 自动更新 | `python3 poster.py --persona x --action auto-update --post-id y` | `./ai-poster.sh auto-update --post-id y` |
| 列出角色 | 直接查看 JSON | `./ai-poster.sh list-personas` |
| 查看统计 | 直接查看 JSON | `./ai-poster.sh stats` |

---

## 🔌 API 端点

| 方法 | 端点 | 描述 |
|------|------|------|
| GET | `/personas` | 列出所有角色 |
| GET | `/personas/:id` | 获取角色详情 |
| GET | `/posts` | 列出所有帖子 |
| GET | `/posts/:id` | 获取帖子详情 |
| POST | `/posts` | 创建帖子 |
| PUT | `/posts/:id` | 更新帖子 |
| GET | `/stats` | 获取统计 |
| POST | `/check/pre-generate` | 预生成检查 |
| POST | `/check/pre-publish` | 预发布检查 |
| POST | `/check/pre-update` | 预更新检查 |
| POST | `/hooks/post-publish` | 发布后钩子 |

---

## 🔄 回滚方案

如需恢复 Python 版本：

```bash
# 1. 备份新脚本 (可选)
mv scripts scripts-bash

# 2. 恢复 Python 脚本
mv .ai/core/backup/poster.py .ai/core/
mv .ai/hooks/backup/*.py .ai/hooks/

# 3. 恢复旧的主脚本
mv ai-poster.sh ai-poster-new.sh
mv ai-poster-old.sh.bak ai-poster.sh

# 4. 确保目录结构
mkdir -p content/{drafts,published,scheduled}
mkdir -p archive/fix
mkdir -p .ai/{contexts,logs}
```

---

## 📝 测试验证

```bash
# 测试初始化
./scripts/hooks/session_init.sh

# 测试预生成检查
echo '{"persona": {"id": "test", "constraints": {"daily_post_limit": 5}}, "title": "Test"}' > /tmp/test.json
./scripts/hooks/pre_generate.sh /tmp/test.json

# 测试预发布检查
echo '{"title": "Test Title Here", "content": "This is a test content that is longer than fifty characters...", "tags": ["test"]}' > /tmp/test.json
./scripts/hooks/pre_publish.sh /tmp/test.json

# 测试 API
curl-client.sh /stats
curl-client.sh /personas
```

---

## ⚠️ 注意事项

1. **依赖检查**: 脚本会自动检测 jq 或 Node.js，如果都没有会给出提示
2. **数据备份**: 改造前已自动备份原 Python 脚本到 `.ai/*/backup/`
3. **权限设置**: 所有 `.sh` 脚本已添加执行权限
4. **路径兼容**: Windows 用户使用 Git Bash 或 WSL 运行

---

## 🎯 改造收益

1. **零依赖**: 无需 Python 环境，只要有 Bash 即可运行
2. **轻量级**: 核心逻辑纯 Bash 实现，启动速度快
3. **API 化**: 支持 curl + JSON 调用，便于集成和扩展
4. **可移植**: 兼容 Linux/macOS/Windows (Git Bash/WSL)
5. **易维护**: 模块化设计，每个功能独立脚本

---

## 📚 相关文档

- `scripts/README.md` - 新系统详细文档
- `.ai/README.md` - 原系统文档 (角色配置等)

---

## 🤝 贡献

欢迎提交 Issue 和 PR！
