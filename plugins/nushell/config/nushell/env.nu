# env.nu — MCP server 环境变量 + 插件注册
# Nushell 启动时先加载 env.nu，再加载 config.nu
# XDG_CONFIG_HOME 指向 config/，配置和 registry 位于 config/nushell/
#
# plugin add 必须在 env.nu 中执行（先于 config.nu），
# 否则 config.nu 中的 plugin use 找不到 registry 会中断整个 config.nu 加载

let bin = ($nu.current-exe | path dirname)
$env.NU_PLUGIN_DIRS = ($env.NU_PLUGIN_DIRS? | default [] | append $bin)
$env.PATH = ($env.PATH | default [] | append $bin)

# 注册 bin/ 下所有 nu_plugin_* 二进制（幂等，重复执行不产生重复条目）
for p in (ls $bin | where name =~ 'nu_plugin_' | get name) {
  plugin add $p
}
