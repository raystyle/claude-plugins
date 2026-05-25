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
  dev-fix/                     # Hook：编码/换行修复 + MSYS路径保护 + 条件式 venv + 自动 git add
  statusline/                  # Hook：四行状态栏（模型/Context/MCP/LSP/Git）
  typescript/                  # LSP：typescript-language-server
  rust/                        # LSP：rust-analyzer
  python/                      # LSP：ty type checker
  psh5/                        # LSP：PowerShellEditorServices (Windows PowerShell 5.x)
  pwsh7/                       # LSP：PowerShellEditorServices (PowerShell 7)
  nushell/                     # MCP Server + LSP（自包含，捆绑 nu 二进制 + 插件）
    bin/                       # nu.exe + nu_plugin_*.exe（browse, formats, gstat, inc, polars, query）
    config/nushell/            # XDG_CONFIG_HOME 驱动的配置目录
      env.nu                   # 环境变量 + plugin add（注册）
      config.nu                # plugin use（激活）+ 运行时配置
```

## Nushell 插件

自包含的 Nushell 完整打包版，基于 [nushell-evo](https://github.com/raystyle/nushell-evo-bin)（0.112.3-evo），捆绑 nu 二进制和 6 个官方插件。通过 `XDG_CONFIG_HOME` 驱动配置发现，首次启动自动注册所有插件。

### nushell-evo — AI 自进化日志

nushell-evo 是 Nushell 的 fork，记录 AI 通过 MCP 执行的每条命令（命令、目录、成功/失败、错误详情），生成 JSONL 审计日志。**自动记录，无需配置**，默认写入工作目录下的 `nu_evo.jsonl`。可通过 `NU_MCP_LOG` 环境变量自定义路径。用于分析 AI 错误模式、训练模型进化、调试 MCP 会话。

### MCP Server（3 个工具）

| 工具 | 功能 |
|------|------|
| `evaluate` | 执行 Nushell 表达式，返回结构化 NUON 结果 + history_index 用于后续分页 |
| `command_help` | 查询 Nushell 命令的帮助文档 |
| `list_commands` | 列出所有可用的 Nushell 命令（支持搜索过滤） |

MCP Server 同时提供 system prompt 指令：优先使用 Nushell 替代其他 shell 工具，禁止在首次执行的管道中截断输出（`first N`/`head`/`tail`），结果自动保存到 `$history` 可后续分页。

### LSP Server

为 `.nu` 文件提供语言智能服务（补全、诊断、hover、跳转定义等），懒加载 — 打开 `.nu` 文件时按需启动。

### 捆绑插件（6 个，167 个命令）

| 插件 | 命令数 | 功能 | 关键命令 |
|------|--------|------|----------|
| **polars** | 146 | DataFrame / 数据分析引擎 | `polars open`、`polars select`、`polars filter`、`polars group-by`、`polars join`、`polars agg`、`polars collect`、`polars save`、`from parquet`/`from csv`/`from json` |
| **browse** | 8 | 浏览器自动化（[nu-browse](https://github.com/raystyle/nu_browse_bin)，定制插件） | `browse open`、`browse goto`、`browse close`、`browse cookie`、`browse ready`、`browse state`、`browse status` |
| **formats** | 6 | 额外文件格式解析 | `from eml`、`from ics`、`from ini`、`from plist`、`from vcf`、`to plist` |
| **query** | 5 | 结构化数据查询 | `query json`、`query xml`、`query web`、`query webpage-info` |
| **gstat** | 1 | Git 仓库状态 | `gstat`（分支、暂存、冲突等一目了然） |
| **inc** | 1 | 语义版本号操作 | `inc major`/`inc minor`/`inc patch` |

### 架构

```text
.claude-plugin/plugin.json    # 插件清单，引用 .mcp.json 和 .lsp.json
.mcp.json                     # MCP: nu.exe --mcp，设 XDG_CONFIG_HOME
.lsp.json                     # LSP: nu.exe --lsp
bin/
  nu.exe                      # Nushell 0.112.3-evo（含 MCP/网络/SQLite/插件支持）
  nu_plugin_browse.exe        # 浏览器自动化
  nu_plugin_polars.exe        # DataFrame 引擎
  nu_plugin_formats.exe       # 格式解析
  nu_plugin_query.exe         # 数据查询
  nu_plugin_gstat.exe         # Git 状态
  nu_plugin_inc.exe           # 版本号操作
  less.exe                    # 分页器
config/nushell/
  env.nu                      # 环境变量 + plugin add（注册，先于 config.nu 执行）
  config.nu                   # plugin use（激活）+ 运行时配置
  plugin.msgpackz             # 插件注册表（首次启动自动生成）
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
- **nushell 插件自包含** — 捆绑了 nu.exe 和 6 个 nu_plugin_* 二进制，通过 `XDG_CONFIG_HOME` 驱动配置发现，首次启动自动注册插件到 `config/nushell/plugin.msgpackz`

## 本地测试

使用 `--plugin-dir` 加载本地插件目录（session-only，不影响全局安装），可重复指定：

```bash
# 全部插件
claude --plugin-dir D:/opensource/claude-plugins/plugins/dev-fix --plugin-dir D:/opensource/claude-plugins/plugins/statusline --plugin-dir D:/opensource/claude-plugins/plugins/typescript --plugin-dir D:/opensource/claude-plugins/plugins/rust --plugin-dir D:/opensource/claude-plugins/plugins/python --plugin-dir D:/opensource/claude-plugins/plugins/psh5 --plugin-dir D:/opensource/claude-plugins/plugins/pwsh7 --plugin-dir D:/opensource/claude-plugins/plugins/nushell

# 只测 nushell 插件
claude --plugin-dir D:/opensource/claude-plugins/plugins/nushell

# 只测 Hook 插件
claude --plugin-dir D:/opensource/claude-plugins/plugins/dev-fix --plugin-dir D:/opensource/claude-plugins/plugins/statusline

# 模拟 statusline 输出
echo '{"model":{"display_name":"glm-5.1"},"context_window":{"used_percentage":56,"current_usage":{"input_tokens":80000,"cache_creation_input_tokens":20000,"cache_read_input_tokens":12000},"context_window_size":200000},"cost":{"total_duration_ms":2690000},"session_id":"test-123","workspace":{"current_dir":"D:/opensource/claude-plugins"}}' | bash plugins/statusline/scripts/statusline.sh
```
