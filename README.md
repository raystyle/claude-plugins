# RAY 的私有 Claude 插件

> MCP servers、LSP configs、Hooks — 专为 Windows 开发环境适配，解决编码、Shell 差异和 LSP 配置问题。

**Windows 适配亮点：**
- **编码/换行自动修复** — 消除 Git Bash 的 `\r` 换行和 UTF-8 编码问题
- **Python venv 自动激活** — 检测 `.venv`/`venv` 目录（支持 `Scripts\` Windows 路径）
- **双 PowerShell LSP** — 分别适配 Windows PowerShell 5.x 和 PowerShell 7
- **Nushell MCP Server** — 结构化类型安全 Shell，对话带持久化 REPL，记录所有命令
- **Statusline 状态栏** — 四行彩色显示模型、Context 用量、MCP/LSP 服务、Git 状态

Skills 已拆分到独立仓库：**[raystyle/skills](https://github.com/raystyle/skills)**

## 插件列表

| 插件 | 类型 | 说明 |
|------|------|------|
| [dev-fix](plugins/dev-fix) | Hook | Windows Git Bash 编码/换行修复 + Python venv 自动激活 + 自动 git add |
| [statusline](plugins/statusline) | Hook | 四行状态栏：模型 + Context(token/进度条/百分比) + MCP/LSP 服务 + Git 分支状态 |
| [typescript](plugins/typescript) | LSP | typescript-language-server（.ts/.tsx/.js/.jsx/.mts/.cts/.mjs/.cjs） |
| [rust](plugins/rust) | LSP | rust-analyzer |
| [python](plugins/python) | LSP | ty type checker（通过 uvx 启动） |
| [psh5](plugins/psh5) | LSP | PowerShellEditorServices（Windows PowerShell 5.x） |
| [pwsh7](plugins/pwsh7) | LSP | PowerShellEditorServices（PowerShell 7） |
| [nushell](plugins/nushell) | MCP+LSP | Nushell MCP server + LSP |

## 安装

```text
/plugin marketplace add raystyle/plugins
/plugin install raystyle@nushell
/plugin install raystyle@dev-fix
```

## 前置条件

所有插件依赖 [oh-my-winclaude](https://github.com/raystyle/oh-my-winclaude) 提供的基础环境（CLI 工具链、运行时、依赖安装）。需先完成 oh-my-winclaude 安装，skill 和 MCP/LSP 才能正常工作。

## 联动项目

- **[oh-my-winclaude](https://github.com/raystyle/oh-my-winclaude)** — Claude Code 基础环境（前置依赖），持续更新中
- **[skills](https://github.com/raystyle/skills)** — Skill 插件市场，持续更新中
- **[nushell-evo](https://github.com/raystyle/nushell-evo-bin)** — Nushell fork，开启完整的 MCP 命令日志
- **[nu-browse](https://github.com/raystyle/nu_browse_bin)** — 为智能体和 Nushell 适配定制的浏览器插件

## 许可证

MIT
