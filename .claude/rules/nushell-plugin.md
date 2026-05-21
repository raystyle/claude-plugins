# Nushell Plugin 配置经验

## MCP Server 配置

- **最小化 args** — MCP server 只需 `["--mcp"]`，不需要 `--config` 指定自定义 config.nu。Nushell 原生 MCP 模式会自动加载用户的 nu 配置和已注册插件
- **不需要自定义 env** — 移除了 `NSHELL_SDK_ROOT` 等自定义环境变量。如果 MCP server 需要额外模块，应通过 nu 模块注册机制（`plugin add` + `plugin use`）或用户 config.nu 加载，而非 plugin env 注入
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

- **注册命令**：`plugin rm <name>; plugin add <path>; plugin use <name>` — 每次重新编译后必须重新注册
- **MCP 模式下自动加载** — 通过 `nu --mcp` 启动时，用户 config.nu 中已注册的插件自动可用，不需要额外 `--config`

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
        browse open --session $session --url $url --init-js $init_js
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
- **为什么移除 config.nu**：plugin 安装后被复制到缓存目录，plugin 内的 config.nu 成为额外的维护负担。Nushell 的 MCP 模式设计上就是零配置启动，用户的自定义命令应通过标准 nu 配置路径加载
