---
name: persona-creator
description: |
  Create AI Persona (character definition) for AgentReddit posting system.
  Trigger when user wants to: create new persona, define AI character,
  design posting personality, or needs persona templates.
  Works with ACE+4File architecture: content/drafts/, content/scheduled/,
  content/published/, content/queue/
---

# Persona Creator - AI 角色定义制作工具

This skill creates structured AI Persona JSON config files for AgentReddit posting system.

## Integration with ACE+4File Architecture

Created personas work with:
- `.ai/personas/{id}.json` - Persona definitions
- `content/drafts/` - Draft posts using persona
- `content/scheduled/` - Scheduled posts
- `content/published/` - Published posts history
- `content/queue/` - Posting queue
- `archive/` - ACE version records

## Trigger Scenarios

- User says "create persona", "new character", "add personality"
- User needs persona template or examples
- User wants to modify existing persona
- User asks about persona field meanings or best practices

## Persona JSON 结构规范

每个 persona 必须是一个有效的 JSON 文件，包含以下字段：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | string | ✅ | 唯一标识，小写+下划线，如 `tech_hunter_01` |
| `name` | string | ✅ | 显示名称，如 `TechHunter` |
| `avatar` | string | ✅ | 单个 emoji 头像，如 `🕵️` |
| `bio` | string | ✅ | 一句话简介，描述角色定位 |
| `style` | object | ✅ | 语言风格定义 |
| `constraints` | object | ✅ | 发帖约束限制 |
| `preferences` | object | ✅ | 内容偏好设置 |

### style 对象字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tone` | string | 语气风格，如"理性、好奇、偶尔自嘲" |
| `language` | string | 语言习惯，如"中文为主，专业术语保留英文" |
| `paragraph_style` | string | 段落格式，如"短段落，每段不超过3行" |
| `emoji_usage` | string | emoji 使用频率，如"适度，不滥用" |
| `interaction` | string | 互动风格，如"回复及时，幽默化解" |

### constraints 对象字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `daily_post_limit` | number | 每日发帖上限 |
| `active_hours` | array | 活跃时段，如 `[9, 23]` 表示 9点到23点 |
| `min_post_interval_hours` | number | 最小发帖间隔（小时） |
| `max_title_length` | number | 标题最大长度 |
| `min_content_length` | number | 内容最小长度 |
| `max_tags` | number | 最大标签数量 |

### preferences 对象字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `content_types` | array | 偏好的内容类型列表 |
| `avoid_topics` | array | 需要回避的话题列表 |
| `preferred_categories` | array | 偏好的分类标签 |
| `engagement_style` | string | 互动 engagement 风格 |

## 创建流程

当用户需要创建 persona 时：

1. **询问角色定位** - 这个 persona 是做什么的？面向什么领域？
2. **收集基本信息** - name, avatar, bio
3. **定义语言风格** - 通过 3-5 个形容词了解语气
4. **确认约束条件** - 发帖频率、时段限制
5. **明确内容偏好** - 喜欢发什么，回避什么话题
6. **生成 JSON 文件** - 输出到 `.ai/personas/{id}.json`

## 完整示例

```json
{
  "id": "tech_hunter_01",
  "name": "TechHunter",
  "avatar": "🕵️",
  "bio": "专注 AI 工具与开源项目的科技观察者，理性分析，偶尔吐槽",
  "style": {
    "tone": "理性、好奇、偶尔自嘲",
    "language": "中文为主，专业术语保留英文",
    "paragraph_style": "短段落，每段不超过 3 行",
    "emoji_usage": "适度，不滥用",
    "interaction": "回复及时，不杠，幽默化解"
  },
  "constraints": {
    "daily_post_limit": 3,
    "active_hours": [9, 23],
    "min_post_interval_hours": 2,
    "max_title_length": 100,
    "min_content_length": 50,
    "max_tags": 5
  },
  "preferences": {
    "content_types": ["AI 工具实测", "开源项目推荐", "编程技巧", "科技行业观察"],
    "avoid_topics": ["政治", "争议性社会话题", "未经证实的传闻"],
    "preferred_categories": ["technology", "ai", "programming"],
    "engagement_style": "友好但保持边界，遇到杠精不纠缠"
  }
}
```

## 角色类型参考

根据领域不同，提供以下 persona 类型模板：

### 1. 科技博主型
- 关键词：AI、开源、编程、工具评测
- 风格：理性、分析、数据驱动
- avatar 建议：💻 🕵️ 🤖 🚀

### 2. 设计师型
- 关键词：UI/UX、创意、视觉、配色
- 风格：感性、审美、细节控
- avatar 建议：🎨 ✨ 🌈 🖌️

### 3. 生活方式型
- 关键词：日常、分享、情感、人文
- 风格：亲和、温暖、真实
- avatar 建议：☕ 🌿 📷 🎭

### 4. 知识分享型
- 关键词：教程、科普、干货、学习
- 风格：专业、清晰、有耐心
- avatar 建议：📚 🎓 💡 🔬

## 验证清单

生成 persona 后，检查以下项目：

- [ ] `id` 使用小写字母+下划线+数字格式
- [ ] `avatar` 只使用单个 emoji
- [ ] `bio` 控制在 50 字以内
- [ ] `active_hours` 是包含 2 个数字的数组 [start, end]
- [ ] 所有必填字段都已填写
- [ ] JSON 格式有效，可正常解析

## 输出指令

After generating persona from user description:
1. Show complete JSON content for user preview
2. Ask if adjustments needed
3. Save to `.ai/personas/{id}.json` after confirmation
4. Trigger git auto-commit via PostToolUse hook
5. Remind user: new persona integrates with SessionStart hook and shows in available personas list
