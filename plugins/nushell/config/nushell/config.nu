# config.nu — MCP server 运行时配置
# 前提：env.nu 中已通过 plugin add 注册插件并生成 registry
# plugin use 是 parser keyword，从 registry 导入当前作用域

try { plugin use browse }
try { plugin use formats }
try { plugin use gstat }
try { plugin use inc }
try { plugin use polars }
try { plugin use query }

$env.config = {
  show_banner: false,
  table: { mode: rounded },
  completions: { quick: true },
  history: { max_size: 5000 },
}
$env.PROMPT_COMMAND = {|| "Nu-MCP > " }
