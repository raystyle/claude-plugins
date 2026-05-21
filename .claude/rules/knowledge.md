---
paths:
  - ".knowledge/**"
---

# .knowledge 研究开发需求

本项目 `.knowledge/` 目录包含 Claude Code 源码和 Nushell 文档，用于研究插件系统行为。

## 源码结构

- `.knowledge/claude_source_code/` — Claude Code 反编译源码
  - `utils/plugins/` — 插件加载、验证、schema 定义
  - `tools/SkillTool/` — Skill 工具实现
  - `skills/loadSkillsDir.ts` — Skill 加载与去重逻辑
  - `src/commands.ts` — 命令注册表（skill/plugin/builtin 合并优先级）
  - `entrypoints/sdk/coreSchemas.ts` — 核心 schema 定义
  - `types/plugin.ts` — 插件类型定义

## 研究原则

- **以源码为准** — 遇到不确定的插件系统行为，先查 `.knowledge/claude_source_code/` 源码确认
- **关键行为已确认**：
  - Skill 和 Plugin skill 同名时按加载顺序 first-match，无警告
  - 加载优先级：bundledSkills > builtinPluginSkills > skillDirCommands > pluginCommands > pluginSkills > COMMANDS
  - LSP 懒加载（打开文件时启动），MCP 随插件启用启动
  - LSP 扩展名冲突时第一个加载的生效，无警告
  - Plugin agent 不支持 permissionMode、hooks、mcpServers 字段
