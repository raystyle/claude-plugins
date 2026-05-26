# Claude Plugins

Claude Code 插件集合。MCP servers、LSP configs、Hooks — 专为 Windows 开发环境适配。

## 插件列表

| 插件 | 类型 | 说明 |
|------|------|------|
| [dev-fix](plugins/dev-fix) | Hook | Windows Git Bash 编码/换行修复 + MSYS 路径保护 + 条件式 venv 激活 + 自动 git add |
| [statusline](plugins/statusline) | Hook | 四行状态栏：模型 + Context(token/进度条/百分比) + MCP/LSP 服务 + Git 分支状态 |
| [typescript](plugins/typescript) | LSP | typescript-language-server（.ts/.tsx/.js/.jsx/.mts/.cts/.mjs/.cjs） |
| [rust](plugins/rust) | LSP | rust-analyzer |
| [python](plugins/python) | LSP | ty type checker（通过 uvx 启动） |
| [psh5](plugins/psh5) | LSP | PowerShellEditorServices（Windows PowerShell 5.x） |
| [pwsh7](plugins/pwsh7) | LSP | PowerShellEditorServices（PowerShell 7） |
| [nushell](plugins/nushell) | MCP+LSP | Nushell 完整打包版（含 polars 等插件）— MCP server + LSP |

## 安装

### 1. 基础环境

通过 [oh-my-winclaude](https://github.com/raystyle/oh-my-winclaude)（omc）安装插件所需的工具链：

```powershell
git clone https://github.com/raystyle/oh-my-winclaude D:\Oh-My-Claude
cd D:\Oh-My-Claude
.\.scripts\init.ps1
```

按需安装依赖：

```powershell
omc install base          # gh、git、aria2、7z、uv（必装）
omc install jq            # statusline JSON 解析需要
omc install node          # TypeScript LSP 前置
omc install tslsp         # TypeScript LSP（需要先装 node）
omc install rust          # Rust LSP（安装 rust + rust-analyzer）
omc install pwsh7         # PowerShell 7 本体（pwsh7 插件需要）
omc install pses          # PowerShellEditorServices（psh5/pwsh7 需要）
```

> **nushell 插件是为 AI agent 原生工具链定制的打包版**（捆绑 nu 二进制 + 6 个插件），内置在插件中避免版本冲突。如果需要系统级开发使用 Nushell，可通过 omc 单独安装：`omc install nushell`。两者独立互不影响。

各插件的 omc 依赖：

| 插件 | 依赖工具 | omc 安装命令 |
|------|----------|-------------|
| **nushell** | 无（自包含，agent 定制版） | `omc install nushell`（系统开发用） |
| **dev-fix** | Git Bash | `omc install base` |
| **statusline** | bash + jq + git | `omc install base` → `omc install jq` |
| **typescript** | node + tslsp | `omc install node` → `omc install tslsp` |
| **rust** | rust | `omc install rust` |
| **python** | uv（base 含） | `omc install base` |
| **psh5** | pses | `omc install pses` |
| **pwsh7** | pwsh7 + pses | `omc install pwsh7` → `omc install pses` |

### 2. 安装插件

```powershell
claude plugin marketplace add https://github.com/raystyle/claude-plugins

# 安装全部插件
$plugins = @('nushell','dev-fix','statusline','typescript','rust','python','pwsh7')
foreach ($p in $plugins) { claude plugin install "raystyle@$p" }
```

> **注意**：psh5 和 pwsh7 映射相同的扩展名，同时安装会冲突。推荐安装 pwsh7（PowerShell 7，性能更好）。如需 psh5，将上面的 `pwsh7` 替换为 `psh5`。

### 3. 更新插件

```powershell
# 刷新 marketplace 缓存
claude plugin marketplace update raystyle

# 更新全部插件
$plugins = @('nushell','dev-fix','statusline','typescript','rust','python','pwsh7')
foreach ($p in $plugins) { claude plugin update "$p@raystyle" }
```

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
| **browse** | 8 | 浏览器自动化（[nu-browse](https://github.com/raystyle/nu_browse_bin)）— 为智能体适配的浏览器控制 |
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

## 联动项目

- [oh-my-winclaude](https://github.com/raystyle/oh-my-winclaude) — 基础环境（Git、Node.js、Python、Rust 等工具链一键安装）
- [skills](https://github.com/raystyle/skills) — Skill 集合（浏览器自动化、GitHub 搜索、AI 对话等）
- [nushell-evo](https://github.com/raystyle/nushell-evo-bin) — Nushell fork，完整的 MCP 命令审计日志
- [nu-browse](https://github.com/raystyle/nu_browse_bin) — 为智能体适配的浏览器 Nushell 插件

## 许可证

MIT
