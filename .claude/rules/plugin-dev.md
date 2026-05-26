---
paths:
  - "**/.claude-plugin/plugin.json"
  - "**/.mcp.json"
  - "**/.lsp.json"
  - "**/.claude-plugin/marketplace.json"
  - "plugins/*/hooks/**"
  - "plugins/*/scripts/**"
---

# Plugin 开发规范

## Schema 和清单

- **Schema 是权威来源** — `utils/plugins/schemas.ts` 中的 Zod schema 定义所有合法字段和验证规则，开发时以此为准
- **版本号双写** — 改版本号时必须同时更新 `marketplace.json` 和每个插件的 `plugins/*/. claude-plugin/plugin.json`，缺一不可。`claude plugin update` 比对的是各插件自己的 plugin.json 版本，不是 marketplace.json
- **JSON 引号转义** — `plugin.json` 是标准 JSON，`args` 中脚本内的双引号必须转义为 `\"` 或改用单引号。修改后务必用 JSON 验证器检查
- **路径变量** — `${CLAUDE_PLUGIN_ROOT}` 和 `${CLAUDE_PLUGIN_DATA}` 在所有配置中可用，替换发生在加载时
- **路径必须相对** — 所有路径以 `./` 开头，相对于 plugin 根目录。安装后 plugin 被复制到缓存，绝对路径和 `../` 会失效

## LSP Server

- **懒加载** — LSP server 在打开匹配扩展名的文件时才启动，不是插件启用时立即启动
- **扩展名冲突** — 多个 LSP server 映射同一扩展名时，只有第一个加载的生效（按插件加载顺序），无警告
- **统一配置** — 所有 LSP 必须包含 `startupTimeout: 120000` 和 `maxRestarts: 3`
- **必需字段**：`command`、`extensionToLanguage`
- **可选字段**：`args`、`env`、`startupTimeout`、`shutdownTimeout`、`restartOnCrash`、`maxRestarts`、`initializationOptions`、`settings`

## MCP Server

- **随插件启动** — 插件启用后 MCP server 自动启动（与 LSP 的懒加载不同）
- **支持格式** — 内联 JSON、`.mcp.json` 文件、MCPB 文件（`.mcpb`/`.dxt`，本地路径或远程 URL）
- **环境变量** — plugin server 自动获得 `CLAUDE_PLUGIN_ROOT` 和 `CLAUDE_PLUGIN_DATA` 环境变量

## Hook

- **Hook events** — 以 `coreSchemas.ts` 中的 `HOOK_EVENTS` 数组为准（当前 27 个事件）
- **Hook 类型**：`command`（shell 命令）、`http`（POST 请求）、`mcp_tool`（MCP 工具调用）、`prompt`（LLM 评估）、`agent`（agentic 验证器）
- **command hook** — 脚本必须可执行（`chmod +x`），必须有 shebang 行，路径必须用 `${CLAUDE_PLUGIN_ROOT}`
- **Setup vs SessionStart** — `Setup` hook 只在 `claude --init` 模式下触发，正常交互会话不触发。需要会话启动时执行的逻辑应使用 `SessionStart`

## Plugin Agent 安全限制

Plugin 提供的 agents **不支持**以下字段（会被忽略并记录警告）：
- `permissionMode`
- `hooks`
- `mcpServers`

需要这些字段的 agent 必须定义在 `.claude/agents/` 而非 plugin 中。

## 目录结构约束

- `plugin.json` 只能放在 `.claude-plugin/` 目录
- skills/、commands/、agents/、hooks/ 等组件目录必须在 plugin **根目录**，不能在 `.claude-plugin/` 内
- `bin/` 目录下的可执行文件会自动添加到 Bash tool 的 PATH

## Plugin Settings 限制

- **PluginSettingsSchema 白名单** — `pluginLoader.ts` 中 `PluginSettingsSchema` 使用 `SettingsSchema().pick({ agent: true }).strip()` 过滤，plugin 的 `settings.json` 只有 `agent` 字段生效，其他字段（如 `statusLine`、`subagentStatusLine`）会被 `.strip()` 静默移除
- **绕过方法** — 通过 Hook（如 `Setup`）在会话启动时将配置写入用户的 `~/.claude/settings.json`
- **优先级** — Plugin settings 优先级最低，所有文件来源（user/project/local）都会覆盖

## 本地测试

- **`--plugin-dir`** — CLI 参数 `claude --plugin-dir <path>` 加载本地插件目录，session-only 不影响全局安装，可重复指定多个目录：`claude --plugin-dir A --plugin-dir B`
- **模拟 statusline 脚本** — 用 echo 构造 JSON 通过管道传给脚本测试输出效果：`echo '{"model":{"display_name":"Opus"},...}' | bash scripts/statusline.sh`
- **开发完成提示测试** — 每次完成插件开发或修改后，在回复末尾附上对应的 `--plugin-dir` 测试命令，方便用户直接复制粘贴验证
