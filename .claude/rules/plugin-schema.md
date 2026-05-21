---
paths:
  - "**/.claude-plugin/plugin.json"
  - "**/.mcp.json"
  - "**/.lsp.json"
---

# Plugin Schema 速查

基于 `.knowledge/claude_source_code/utils/plugins/schemas.ts` 源码 Zod schema。

## plugin.json 必需/可选字段

| 字段 | 必需 | 类型 | 说明 |
|------|------|------|------|
| `name` | 是 | string | 唯一标识符，kebab-case，不允许空格 |
| `version` | 否 | string | 语义版本号 |
| `description` | 否 | string | 简短描述 |
| `author` | 否 | object | `{ name: string, email?: string, url?: string }` |
| `homepage` | 否 | string | 有效 URL |
| `repository` | 否 | string | 源码 URL |
| `license` | 否 | string | SPDX 标识符 |
| `keywords` | 否 | string[] | 标签 |
| `dependencies` | 否 | array | 插件依赖引用 |
| `mcpServers` | 否 | 多态 | 内联 JSON / 外部文件路径（`"./.mcp.json"`）/ MCPB URL |
| `lspServers` | 否 | 多态 | 内联 JSON / 外部文件路径（`"./.lsp.json"`） |
| `hooks` | 否 | 多态 | 内联配置 / 外部文件路径 |
| `skills` | 否 | 多态 | 路径 / 路径数组 |
| `commands` | 否 | 多态 | 路径 / 路径数组 / 对象映射 |
| `agents` | 否 | 多态 | 路径 / 路径数组 |
| `settings` | 否 | object | 只有 `agent` 子字段生效，其他被 `.strip()` 移除 |
| `userConfig` | 否 | object | 用户可配置项定义 |

## MCP Server 字段（stdio 类型）

| 字段 | 必需 | 类型 | 说明 |
|------|------|------|------|
| `command` | 是 | string | 可执行文件路径，不允许包含空格 |
| `args` | 否 | string[] | 命令行参数 |
| `env` | 否 | object | 环境变量，支持 `${VAR}` 变量替换 |
| `type` | 待确认 | string | 传输类型，stdio 可能有默认值 |

## LSP Server 字段

| 字段 | 必需 | 类型 | 说明 |
|------|------|------|------|
| `command` | 是 | string | 可执行文件路径 |
| `args` | 否 | string[] | 命令行参数 |
| `extensionToLanguage` | 是 | object | `{ ".ext": "language-id" }` |
| `transport` | 否 | string | `"stdio"`（默认）/ `"socket"` |
| `env` | 否 | object | 环境变量 |
| `initializationOptions` | 否 | any | LSP 初始化选项 |
| `settings` | 否 | any | didChangeConfiguration 设置 |
| `startupTimeout` | 否 | number | 启动超时（毫秒） |
| `shutdownTimeout` | 否 | number | 关闭超时（毫秒） |
| `restartOnCrash` | 否 | boolean | 崩溃重启（未实现） |
| `maxRestarts` | 否 | number | 最大重启次数，默认 3 |

## Hook 事件类型

`PreToolUse`、`PostToolUse`、`PostToolUseFailure`、`UserPromptSubmit`、`SessionStart`、`Setup`、`SubagentStart`、`PermissionDenied`、`PermissionRequest`、`Elicitation`、`ElicitationResult`、`CwdChanged`、`FileChanged`、`Notification`、`WorktreeCreate`

## Hook 类型

`command`（shell 命令）、`http`（POST 请求）、`prompt`（LLM 评估）、`agent`（agentic 验证器）

## 路径规则

- 所有相对路径以 `./` 开头，相对于 plugin 根目录
- 不允许 `../` 路径穿越
- `${CLAUDE_PLUGIN_ROOT}` 和 `${CLAUDE_PLUGIN_DATA}` 变量在加载时替换
- 安装后 plugin 被复制到缓存目录，硬编码绝对路径会失效
- `bin/` 目录下的可执行文件自动加入 Bash tool 的 PATH

## Plugin Settings 限制

- `PluginSettingsSchema` 使用 `SettingsSchema().pick({ agent: true }).strip()` 过滤
- 只有 `agent` 字段生效，其他（如 `statusLine`、`subagentStatusLine`）被静默移除
- 绕过方法：通过 Hook（如 `Setup`）在会话启动时将配置写入用户的 `~/.claude/settings.json`
