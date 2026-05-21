---
paths:
  - "**/*.nu"
  - "**/config/nushell/**"
  - "plugins/nushell/**"
---

# Nushell Plugin 配置经验

## MCP Server 配置

- **`XDG_CONFIG_HOME` 驱动配置发现** — `.mcp.json` 中设 `XDG_CONFIG_HOME` 指向 `${CLAUDE_PLUGIN_ROOT}/config`，Nushell 自动在 `config/nushell/` 下查找 `env.nu`、`config.nu`、`plugin.msgpackz`，无需 `--config`/`--env-config` 参数
- **禁止 `--plugins` 参数** — JSON 数组字符串会被 Nushell 当作相对路径拼接到 cwd，导致 `os error 267（目录名称无效）`。插件注册必须在 config.nu 中通过 `plugin add` 完成
- **`plugin add` vs `plugin use`（0.93+ 两阶段机制）**：
  - `plugin add <path>` — 运行插件二进制，提取签名，**持久化**写入 `plugin.msgpackz` 注册表。只需执行一次（安装/升级时），幂等
  - `plugin use <name>` — Parser keyword（解析时关键字），从注册表读取签名，把插件命令**导入当前会话作用域**。每次启动都需要执行
  - **两阶段分离**：`add` 不等于可用，`use` 不等于注册。必须先 `add` 持久化，再 `use` 加载到会话
- **`plugin use` 在 config.nu 中的限制** — 作为 parser keyword，`plugin use` 在 config.nu 解析阶段执行，此时 `plugin add` 的运行时代码尚未执行。如果注册表中没有对应条目（未预先 `add` 过），会报 "Plugin registry file can't be opened"。`try {}` 无法捕获 parser 阶段错误
- **当前方案**：`env.nu`（先执行）中做 `plugin add` 注册插件生成 registry → `config.nu`（后执行）中做 `plugin use` 激活插件。`plugin add` 必须在 `env.nu` 中，否则 `config.nu` 的 `plugin use` 找不到 registry 会中断整个 `config.nu` 加载
- **注册流程**：`env.nu` 设置 `PATH`/`NU_PLUGIN_DIRS` + `plugin add` 注册所有 `nu_plugin_*` 二进制 → `config.nu` 中 `plugin use` 激活插件
- **nu 模块不属于 plugin** — `.nu` 模块（browse.nu、github.nu 等）和 JS SDK 已迁移到 [skills](https://github.com/raystyle/skills) 项目。Plugin 只负责启动 MCP server + LSP，不捆绑业务模块

## LSP Server 配置

- **必需字段**：`command`、`args`（`["--lsp"]`）、`extensionToLanguage`
- **统一超时配置**：`startupTimeout: 120000`、`maxRestarts: 3`（与其他 LSP plugin 保持一致）
- **Nushell LSP 同时服务 MCP** — 同一个 `nu` 二进制既提供 MCP server 又提供 LSP server，通过不同参数（`--mcp` vs `--lsp`）区分

## Nu 模块加载技巧

### 模块依赖模式

- **`use` 声明依赖链** — nu 模块之间通过 `use` 声明依赖。例如 grok.nu、twitter.nu、google.nu 都 `use browse.nu *` 来复用浏览器操作函数。这是 nu 的标准模块复用方式
- **`export def` 暴露公共 API** — 每个模块通过 `export def` 导出命令，内部辅助函数不加 `export` 保持私有（如 `google-ensure`、`article-path`）
- **环境变量传递配置** — `$env.NSHELL_SDK_ROOT? | default ($env.FILE_PWD? | default "")` 模式：优先读 env 变量，fallback 到 `$env.FILE_PWD`（nu 模块文件所在目录），最后 fallback 到当前目录

### Nu 原生插件（二进制）加载

- **注册命令**：`plugin add <path>`（幂等，持久化到 `plugin.msgpackz`）— 无需 `plugin rm`
- **加载命令**：`plugin use <name>`（parser keyword，会话级，从注册表导入作用域）— 每次启动需重新执行
- **在 config.nu 中只能用 `plugin add`** — `plugin use` 是 parser keyword，在解析阶段执行时 `plugin add` 的运行时代码尚未运行

### Nu 模块 vs Nu 插件

| 类型 | 格式 | 加载方式 | 示例 |
|------|------|----------|------|
| Nu 模块（module） | `.nu` 脚本 | `use` / `source` | browse.nu、grok.nu |
| Nu 插件（plugin） | 二进制可执行 | `plugin add` + `plugin use` | nu_plugin_browse.exe |

- **模块适合**：纯 nu 脚本封装、命令组合、业务逻辑
- **插件适合**：需要外部依赖（Chromium、系统 API）、性能敏感操作、自定义数据类型

### browse 插件的 session 管理模式

- **命名 session** — 每个服务使用独立 session：`grok`、`twitter`、`google`。session 名决定 profile 目录名（`.nu_browse_profile_<session>/`）
- **首次有头，后续无头** — 首次用 `--with-head` 打开让用户过 CAPTCHA/登录，cookie 持久化在 profile 中，后续自动复用
- **SDK 注入** — `--init-js <sdk-path>` 在页面加载时注入 JS SDK，注入后全局对象（`__browse.*`、`__grok`、`__tw`）可用

### 数据契约（跨层 JSON 传递）

- **所有跨层结构化数据都是 JSON string**：`message.post.output`、`message.pre.output`、`network[].body`
- **`wrap_eval_js` 自动 `JSON.stringify`** — eval 表达式不需要手动 `JSON.stringify`，否则双重 stringify 导致 `from json` 返回 string
- **async 方法例外** — SDK 中 async 方法（`list()`、`getMessages()`、`deleteAPI()`）需要 `.then(r=>JSON.stringify(r))`，同步方法（`lastResult()`、`readyCheck()`、`info()`）不需要
- **调用方统一 `| from json` 解析** — 拿到 output 后一律 `from json` 反序列化为 nu record/list

### 可选参数处理模式

nu 不支持可选参数的重载，browse.nu 使用条件分支手动分派：

```nu
export def browser-open [
    --session: string = "default"
    --with-head
    --url: string = ""
    --init-js: string = ""
]: nothing -> record {
    let has_url = ($url | is-not-empty)
    let has_init_js = ($init_js | is-not-empty)
    if $has_url and $has_init_js {
        browse open --session $session --url $url --init-js $init-js
    } else if $has_url {
        browse open --session $session --url $url
    } else {
        browse open --session $session
    }
}
```

这种模式用于包装 nu_plugin_browse 的命令，因为原生插件不支持可选 flag 组合。所有 browse wrapper 函数（browser-open、browser-goto 等）都用这个模式。

## 历史决策

- **v0.1.0 → 重构**：最初 MCP server 使用 `--config` 加载 plugin 内的 config.nu 来 source 所有 nu 模块，并通过 env 传入 SDK 路径。重构后简化为纯 `--mcp` 启动，模块管理交给用户 nu 配置和 skills 项目
- **v1.0.0 → 引回 --config**：需要在 MCP server 中注册 nu_plugin_browse 等二进制插件，纯 `--mcp` 依赖用户级配置不可靠。通过 `--config`/`--env-config` 指向 plugin 内的配置文件实现自包含
- **为什么不用 `--plugins`**：该参数接收 JSON 数组字符串，但 Nushell 将其当作相对路径拼接到 cwd，生成无效路径触发 `os error 267`。改用 config.nu 中的 `plugin add` 运行时注册
- **为什么 `plugin add` 放 env.nu 而非 config.nu**：`plugin use` 是 parser keyword（0.93+），在 config.nu 解析阶段优先于运行时代码执行。如果 `plugin add` 也放在 config.nu 中，`plugin use` 解析时 registry 尚不存在，会报错中断整个 `config.nu` 加载（包括后续的 `$env.config`）。将 `plugin add` 前移到 `env.nu`（先于 `config.nu` 执行），registry 在 `config.nu` 解析时已存在，`plugin use` 即可正常工作
- **v2.0.0 → XDG_CONFIG_HOME 驱动**：不再使用 `--config`/`--env-config` 参数，改用 `XDG_CONFIG_HOME` 指向 `config/` 目录，Nushell 自动在 `config/nushell/` 下查找 `env.nu`、`config.nu`、`plugin.msgpackz`。配置与二进制分离，目录结构更清晰
