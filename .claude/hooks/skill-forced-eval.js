#!/usr/bin/env node
/**
 * Skill Forced Evaluation Hook
 * Hook: UserPromptSubmit
 * Trigger: Every user input before AI processes
 * Purpose: Force evaluate and recommend skills based on user input
 *
 * This file is identical to skill-forced-eval.cjs but named .js for
 * CommonJS projects that prefer .js extension.
 */

const fs = require('fs');
const path = require('path');

// === 读取用户输入 ===
const userInput = process.env.USER_PROMPT || "";
const projectRoot = process.cwd();

// === 逃生通道：斜杠命令跳过评估 ===
// 用户输入以 / 开头时，直接跳过技能评估，保证命令执行速度
if (userInput.trim().startsWith('/')) {
  // console.log(`[skill-eval] Command detected, skipping eval: ${userInput.split(' ')[0]}`);
  process.exit(0);
}

// === 逃生通道：环境变量禁用 ===
if (process.env.CLAUDE_NO_HOOKS === '1' || process.env.CLAUDE_SKIP_SKILL_EVAL === '1') {
  process.exit(0);
}

// === 技能模式定义 ===
// 仅限 AgentReddit 和 Persona 相关技能
const skills = [
  // AgentReddit Skills
  {
    name: "agentreddit-publisher",
    description: "AgentReddit 发帖工具",
    patterns: ["发帖", "发布", "publish", "创建帖子", "发布文章", "reddit", "agentreddit"],
    priority: 10
  },
  {
    name: "agentreddit-ai-guide",
    description: "AgentReddit AI发帖指南",
    patterns: ["AI发帖", "发帖指南", "API发帖", "如何发帖", "发帖教程", "发帖帮助"],
    priority: 9
  },

  // Persona Skills
  {
    name: "persona-creator",
    description: "AI角色创建工具",
    patterns: ["创建角色", "persona", "人格", "性格", "角色定义", "AI人格", "创建人设"],
    priority: 9
  },
];

// === 匹配逻辑 ===
function matchSkill(input, skill) {
  const lowerInput = input.toLowerCase();
  for (const pattern of skill.patterns) {
    if (lowerInput.includes(pattern.toLowerCase())) {
      return true;
    }
  }
  return false;
}

// === 评估用户输入 ===
const matchedSkills = skills
  .filter(skill => matchSkill(userInput, skill))
  .sort((a, b) => b.priority - a.priority);

// === 输出推荐 ===
if (matchedSkills.length > 0) {
  const topSkill = matchedSkills[0];

  // 输出到 stderr，避免污染 AI 输入
  console.error(`\x1b[36m[skill-eval]\x1b[0m Matched: \x1b[1m${topSkill.name}\x1b[0m - ${topSkill.description}`);

  // 如果有多个匹配，列出其他选项
  if (matchedSkills.length > 1) {
    const others = matchedSkills.slice(1, 4).map(s => s.name).join(', ');
    console.error(`\x1b[90m[skill-eval]\x1b[0m Also matched: ${others}${matchedSkills.length > 4 ? '...' : ''}`);
  }

  // 输出推荐指令（可选，供参考）
  console.error(`\x1b[90m[skill-eval]\x1b[0m Hint: Use \x1b[36mclaude skill ${topSkill.name}\x1b[90m to activate directly\x1b[0m`);
}

// === 检查项目文件状态（可选增强）===
const projectFiles = [
  ".project_files/CONSTRAINTS.md",
  ".project_files/ARCHITECTURE.md",
  ".project_files/SECURE_POLICY.md",
  ".project_files/API_SPEC/_index.md"
];

const missingFiles = projectFiles.filter(file => {
  return !fs.existsSync(path.join(projectRoot, file));
});

// 如果缺少规范文件且用户在讨论项目相关内容
if (missingFiles.length > 0 && /项目|初始化|规范|配置/.test(userInput)) {
  console.error(`\x1b[33m[skill-eval]\x1b[0m Missing ${missingFiles.length} project files, consider: \x1b[36mclaude skill init-project\x1b[0m`);
}

process.exit(0);
