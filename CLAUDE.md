# RAY 的私有 Claude 插件

MCP servers、LSP configs、Hooks — 不含 Skills（已拆分到 [skills](https://github.com/raystyle/skills)）。

## 联动项目

- **[oh-my-winclaude](https://github.com/raystyle/oh-my-winclaude)** — Claude Code 基础环境，持续更新中
- **[skills](https://github.com/raystyle/skills)** — Skill 插件库，持续更新中
- **[nushell-evo](https://github.com/raystyle/nushell-evo-bin)** — Nushell fork，开启完整的 MCP 命令日志
- **[nu-browse](https://github.com/raystyle/nu_browse_bin)** — 为智能体和 Nushell 适配定制的浏览器插件

## 项目结构

```text
.claude-plugin/
  marketplace.json             # Marketplace 注册（8 个插件：1 MCP + 5 LSP + 2 Hook）
plugins/
  dev-fix/                     # Hook：编码/换行修复 + Python venv + 自动 git add
  statusline/                  # Hook：四行状态栏（模型/Context/MCP/LSP/Git）
  typescript/                  # LSP：typescript-language-server
  rust/                        # LSP：rust-analyzer
  python/                      # LSP：ty type checker
  psh5/                        # LSP：PowerShellEditorServices (Windows PowerShell 5.x)
  pwsh7/                       # LSP：PowerShellEditorServices (PowerShell 7)
  nushell/                     # MCP Server + LSP
```

## Statusline 插件

四行彩色状态栏，自动注入到 Claude Code 界面底部：

```text
Model: glm-5.1  │  Ctx: ▓▓▓▓░░░░░░ 112K/200K 56%  │  Time: 44m50s
MCP: 4_5v_mcp · plugin_nushell_nu · web_reader
LSP: nushell · pwsh7 · python · rust · typescript
Branch: main  │  Staged: 5  │  Modified: 2  │  Dir: D:/opensource/Plugins
```

- **Line 1** — 模型名、Context 用量（进度条 + token 数 + 百分比）、会话时长。Context ≥80% 变红警告
- **Line 2** — MCP 服务列表（SessionStart 从配置发现，PostToolUse 自动累积）
- **Line 3** — LSP 服务列表（从已安装插件检测）
- **Line 4** — Git 分支/状态、工作目录

## 注意事项

- **psh5 和 pwsh7 会冲突** — 两者映射相同扩展名（.ps1/.psm1/.psd1），同时启用时只有先加载的生效。按需只启用一个
- **LSP 懒加载** — LSP server 不是插件启用时立即启动，而是打开匹配扩展名的文件时按需启动
- **MCP server 随插件启用启动** — 与 LSP 不同，MCP server 在插件启用后自动启动
- **MCP 服务在首次工具调用后显示** — PostToolUse hook 通过 `mcp__*` matcher 捕获工具名提取服务名

## 本地测试

使用 `--plugin-dir` 加载本地插件目录（session-only，不影响全局安装），可重复指定：

```bash
# 全部插件
claude --plugin-dir D:/opensource/Plugins/plugins/dev-fix --plugin-dir D:/opensource/Plugins/plugins/statusline --plugin-dir D:/opensource/Plugins/plugins/typescript --plugin-dir D:/opensource/Plugins/plugins/rust --plugin-dir D:/opensource/Plugins/plugins/python --plugin-dir D:/opensource/Plugins/plugins/psh5 --plugin-dir D:/opensource/Plugins/plugins/pwsh7 --plugin-dir D:/opensource/Plugins/plugins/nushell

# 只测 Hook 插件
claude --plugin-dir D:/opensource/Plugins/plugins/dev-fix --plugin-dir D:/opensource/Plugins/plugins/statusline

# 模拟 statusline 输出
echo '{"model":{"display_name":"glm-5.1"},"context_window":{"used_percentage":56,"current_usage":{"input_tokens":80000,"cache_creation_input_tokens":20000,"cache_read_input_tokens":12000},"context_window_size":200000},"cost":{"total_duration_ms":2690000},"session_id":"test-123","workspace":{"current_dir":"D:/opensource/Plugins"}}' | bash plugins/statusline/scripts/statusline.sh
```
