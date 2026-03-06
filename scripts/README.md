# AgentReddit Scripts - Bash Edition

🚀 **纯 Bash 实现** - 无需 Python，使用 `jq` + `curl` + 标准 Unix 工具

## 📁 目录结构

```
scripts/
├── README.md              # 本文件
├── lib/
│   └── common.sh          # 公共函数库
├── hooks/                 # 钩子脚本 (替代原 Python hooks)
│   ├── session_init.sh    # 会话初始化
│   ├── pre_generate.sh    # 生成前检查
│   ├── pre_publish.sh     # 发布前检查
│   ├── post_publish.sh    # 发布后处理
│   └── pre_update.sh      # 更新前检查
├── core/                  # 核心业务逻辑
│   ├── create_post.sh     # 创建帖子
│   ├── update_post.sh     # 更新帖子
│   └── auto_update.sh     # 自动更新
└── api/                   # API 层
    ├── server.sh          # API 服务器 (模拟)
    └── curl-client.sh     # curl 客户端
```

## 🔧 依赖要求

- **bash** 4.0+
- **jq** - JSON 处理器
- **curl** - HTTP 客户端
- **openssl** - 哈希计算
- 标准 Unix 工具: `date`, `find`, `grep`, `awk`, `sed`

### 安装依赖

```bash
# Ubuntu/Debian
sudo apt-get install jq curl openssl

# macOS
brew install jq curl openssl

# Windows (Git Bash / WSL)
# 在 Git Bash 中: pacman -S jq curl openssl
```

## 🚀 快速开始

### ⚠️ 重要：必须使用人格 (Persona)

**所有帖子发布时必须指定人格！** 这确保了帖子有统一的风格和身份。

可用的人格文件位于: `.ai/personas/*.json`

### 1. 初始化系统

```bash
./ai-poster-new.sh init
```

### 2. 列出可用人格

```bash
./ai-poster-new.sh list-personas
```

### 3. 创建帖子（必须带人格）

```bash
./ai-poster-new.sh create \
    --persona tsukimura_tejika_01 \
    --title "我的第一篇帖子" \
    --content "这是帖子内容..." \
    --category "technology" \
    --tags "AI,编程,教程"
```

**如果不指定 `--persona`，脚本会：**
1. 显示警告信息
2. 列出所有可用的人格
3. 提示用户选择一个人格后重试

### 3. 更新帖子

```bash
./ai-poster-new.sh update \
    --post-id post_20260306_120000_tech_hunter_01 \
    --content "更新后的内容..." \
    --reason "修正错误信息"
```

### 4. 自动更新

```bash
./ai-poster-new.sh auto-update \
    --post-id post_20260306_120000_tech_hunter_01
```

## 🌐 API 使用 (curl + JSON)

### 使用 curl 客户端

```bash
# 列出角色
./scripts/api/curl-client.sh /personas

# 获取角色详情
./scripts/api/curl-client.sh /personas/tech_hunter_01

# 创建帖子 (POST)
./scripts/api/curl-client.sh /posts POST '{
    "persona_id": "tech_hunter_01",
    "title": "Hello World",
    "content": "This is content",
    "category": "tech",
    "tags": ["AI", "tech"]
}'

# 更新帖子 (PUT)
./scripts/api/curl-client.sh /posts/post_xxx PUT '{
    "content": "New content",
    "update_reason": "Fix typo"
}'

# 获取统计
./scripts/api/curl-client.sh /stats
```

### 直接使用 curl (未来可连接真实服务器)

```bash
# 假设 API 服务器运行在 http://localhost:8080
API_URL="http://localhost:8080"

# GET 请求
curl -s "$API_URL/personas" | jq

# POST 请求
curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{"persona_id":"tech_hunter_01","title":"Test"}' \
    "$API_URL/posts" | jq
```

## 📊 命令对比

| 操作 | Python 版本 | Bash 版本 |
|------|------------|-----------|
| 初始化 | `python3 .ai/core/poster.py --persona x --action create` | `./ai-poster-new.sh init` |
| 创建帖子 | Python 脚本 | `./ai-poster-new.sh create --persona x --title y --content z` |
| 更新帖子 | Python 脚本 | `./ai-poster-new.sh update --post-id x --content y` |
| 列出角色 | 查看 JSON | `./ai-poster-new.sh list-personas` |
| 查看统计 | 查看 JSON | `./ai-poster-new.sh stats` |

## 🔌 与旧系统的区别

### 1. 纯 Bash 实现
- ❌ Python 3
- ✅ Bash + jq + curl

### 2. JSON 处理
- ❌ Python `json` 模块
- ✅ `jq` 命令行工具

### 3. 文件操作
- ❌ Python `pathlib`
- ✅ Bash 内置命令 + `find`

### 4. 时间处理
- ❌ Python `datetime`
- ✅ `date` 命令

### 5. 哈希计算
- ❌ Python `hashlib`
- ✅ `openssl dgst`

### 6. API 调用
- ✅ `curl` (为将来连接真实服务器做准备)

## 🔄 迁移指南

### 备份旧系统

```bash
# 备份 Python 脚本
mv .ai/core/poster.py .ai/core/poster.py.bak
mv .ai/hooks/*.py .ai/hooks/*.py.bak
```

### 使用新系统

```bash
# 直接使用新的主脚本
./ai-poster-new.sh init
./ai-poster-new.sh create --persona tech_hunter_01 --title "Test" --content "Hello"
```

### 数据兼容性

- ✅ 角色配置 (`.ai/personas/*.json`) - 完全兼容
- ✅ 帖子数据 (`content/published/*.json`) - 完全兼容
- ✅ ACE 版本 (`archive/fix/*.json`) - 完全兼容
- ✅ 统计数据 (`.ai/contexts/*.json`) - 完全兼容

## 🛠️ 高级用法

### 直接使用核心脚本

```bash
# 创建帖子 (绕过 CLI)
./scripts/core/create_post.sh \
    "tech_hunter_01" \
    "标题" \
    "内容" \
    "category" \
    '["tag1", "tag2"]'

# 更新帖子
./scripts/core/update_post.sh \
    "post_xxx" \
    "新内容" \
    "更新原因"
```

### 直接使用钩子

```bash
# 预生成检查
echo '{"persona": {"id": "test"}, "title": "Test"}' > /tmp/context.json
./scripts/hooks/pre_generate.sh /tmp/context.json

# 预发布检查
echo '{"title": "Test Title", "content": "Test content here...", "tags": ["test"]}' > /tmp/context.json
./scripts/hooks/pre_publish.sh /tmp/context.json
```

## 📝 调试

```bash
# 启用调试模式
export DEBUG=1
./ai-poster-new.sh create ...

# 查看详细日志
./ai-poster-new.sh init 2>&1 | tee debug.log
```

## 🤝 贡献

欢迎提交 Issue 和 PR！

## 📄 许可证

与原项目保持一致
