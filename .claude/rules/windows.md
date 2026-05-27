# Windows 兼容性规范

本项目所有插件专为 Windows 开发环境设计。

## dev-fix Hook（编码/换行修复）

- `bash-fix.sh` 通过 `tr -d '\r'` 消除 Git Bash 的 CR 换行问题
- 自动设置 UTF-8 编码环境（`PYTHONUTF8`、`PYTHONIOENCODING`、`LESSCHARSET`、`LANG`、`LC_ALL`）
- locale 使用 `C.UTF-8`（通用），不要硬编码特定语言
- 设置 `MSYS_NO_PATHCONV=1` 和 `MSYS2_ARG_CONV_EXCL='*'` 防止 Git Bash 路径转换破坏命令参数
- Python venv 仅在命令直接使用 python/pip/pytest 等工具时自动激活，uv/conda/pipx/poetry 命令跳过
- venv 检测优先查找 `Scripts/activate`（Windows），其次 `bin/activate`（Linux/Mac）
- `git-add.sh` 在 Write/Edit/MultiEdit 后自动 `git add`，跳过不存在文件和 vendor 目录（node_modules 等）
- `error-fix-hint.sh`（PostToolUseFailure）检测两类常见 Bash 命令失败原因，通过 `additionalContext` 注入修正提示：
  - **Windows 反斜杠路径** — 用 jq `test("[A-Za-z]:\\\\")` 检测驱动器路径，提示改为正斜杠
  - **PowerShell cmdlet 误用** — 用 jq `test("Get-ChildItem|Set-Content|...")` 检测 PS 语法，提示改用 Unix 工具或 PowerShell tool
  - 检测用 jq 正则而非 bash `[[ =~ ]]`，避免 bash 转义反斜杠的陷阱

## PowerShell LSP 冲突

- **psh5**（Windows PowerShell 5.x）和 **pwsh7**（PowerShell 7）映射相同的扩展名（.ps1/.psm1/.psd1）
- 同时启用时只有先加载的生效，无警告无报错
- **必须只启用其中一个**，根据系统安装的 PowerShell 版本选择：
  - 只有 Windows PowerShell 5.x → 启用 psh5
  - 只有 PowerShell 7 → 启用 pwsh7
  - 两者都有 → 推荐 pwsh7（性能更好，功能更全）
- Start-PsesStdio.ps1 通过 `Get-Module -ListAvailable PowerShellEditorServices` 自动发现模块，psh5 和 pwsh7 使用相同的脚本

## 路径处理

- plugin.json 中使用 `${CLAUDE_PLUGIN_ROOT}` 引用插件目录，不要硬编码路径
- Bash hook 脚本中使用 `$CLAUDE_PROJECT_DIR` 而非硬编码项目路径
- 文件路径用正斜杠 `/`（Git Bash 兼容），避免反斜杠 `\`
