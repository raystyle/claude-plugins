# RAY 的私有 Claude 插件

> MCP servers、LSP configs、Hooks — 专为 Windows 开发环境适配，解决编码、Shell 差异和 LSP 配置问题。

**Windows 适配亮点：**
- **编码/换行自动修复** — 消除 Git Bash 的 `\r` 换行和 UTF-8 编码问题
- **Python venv 自动激活** — 检测 `.venv`/`venv` 目录（支持 `Scripts\` Windows 路径）
- **双 PowerShell LSP** — 分别适配 Windows PowerShell 5.x 和 PowerShell 7
- **Nushell 完整打包版** — 自包含的 MCP server + LSP，捆绑 nu 二进制和 6 个插件（167 个命令）
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
| [nushell](plugins/nushell) | MCP+LSP | Nushell 完整打包版（含 polars 等插件）— MCP server + LSP |

## Nushell 插件详解

自包含的 [Nushell](https://www.nushell.sh/) 完整打包版，基于 [nushell-evo](https://github.com/raystyle/nushell-evo-bin)（0.112.3），捆绑 nu 二进制和 6 个插件。通过 `XDG_CONFIG_HOME` 驱动配置发现，首次启动自动注册所有插件，无需额外配置。

基于 [nushell-evo](https://github.com/raystyle/nushell-evo-bin) — Nushell fork，**自动记录** AI 通过 MCP 执行的每条命令，生成 JSONL 审计日志。用于分析 AI 错误模式、训练模型进化、调试 MCP 会话。[查看完整文档 →](https://github.com/raystyle/nushell-evo-bin)

### MCP Server（3 个工具）

| 工具 | 功能 |
|------|------|
| `evaluate` | 执行 Nushell 表达式，返回结构化 NUON 结果 + `history_index` 用于后续分页 |
| `command_help` | 查询 Nushell 命令的帮助文档 |
| `list_commands` | 列出所有可用的 Nushell 命令（支持搜索过滤） |

### LSP Server

为 `.nu` 文件提供语言智能服务（补全、诊断、hover、跳转定义等），懒加载 — 打开 `.nu` 文件时按需启动。

### 捆绑插件（6 个，167 个命令）

| 插件 | 命令数 | 功能 |
|------|--------|------|
| **polars** | 146 | DataFrame / 数据分析引擎（`from parquet`/`csv`/`json`、`polars filter`/`group-by`/`join`） |
| **browse** | 8 | 浏览器自动化（[nu-browse](https://github.com/raystyle/nu_browse_bin)，定制插件）— 为智能体适配的浏览器控制。[查看完整文档 →](https://github.com/raystyle/nu_browse_bin) |
| **formats** | 6 | 额外文件格式解析（`from eml`/`ics`/`ini`/`plist`/`vcf`） |
| **query** | 5 | 结构化数据查询（`query json`/`xml`/`web`） |
| **gstat** | 1 | Git 仓库状态（`gstat`） |
| **inc** | 1 | 语义版本号操作（`inc major`/`minor`/`patch`） |

### 目录结构

```text
plugins/nushell/
  .claude-plugin/plugin.json    # 插件清单，引用 .mcp.json 和 .lsp.json
  .mcp.json                     # MCP: nu.exe --mcp，设 XDG_CONFIG_HOME
  .lsp.json                     # LSP: nu.exe --lsp
  bin/
    nu.exe + nu_plugin_*.exe    # Nushell 0.112.3-evo + 6 个插件二进制
  config/nushell/
    env.nu                      # 环境变量 + plugin add（注册）
    config.nu                   # plugin use（激活）+ 运行时配置
    plugin.msgpackz             # 插件注册表（首次启动自动生成）
```

## 安装

```text
# 添加市场源（使用 HTTPS URL）
/plugin marketplace add https://github.com/raystyle/claude-plugins

# 安装插件
/plugin install raystyle@nushell
/plugin install raystyle@dev-fix
/plugin install raystyle@statusline
```

## 前置条件

编程和 CLI 环境使用 [oh-my-winclaude](https://github.com/raystyle/oh-my-winclaude)（Git、Node.js、Python、Rust 等工具链一键安装）。

> **注意：nushell 插件是完全自包含的**，捆绑了自己的 `nu.exe` 和所有插件二进制，**不要通过 oh-my-winclaude 再安装 Nushell**，避免版本冲突。

## 联动项目

- **[oh-my-winclaude](https://github.com/raystyle/oh-my-winclaude)** — Claude Code 基础环境（前置依赖），持续更新中
- **[skills](https://github.com/raystyle/skills)** — Skill 插件市场，持续更新中
- **[nushell-evo](https://github.com/raystyle/nushell-evo-bin)** — Nushell fork，开启完整的 MCP 命令日志
- **[nu-browse](https://github.com/raystyle/nu_browse_bin)** — 为智能体和 Nushell 适配定制的浏览器插件

## 许可证

MIT
