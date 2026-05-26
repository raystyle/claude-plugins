# env.nu — MCP server 环境变量 + 插件注册
# Nushell 启动时先加载 env.nu，再加载 config.nu
# XDG_CONFIG_HOME 指向 config/，配置和 registry 位于 config/nushell/
#
# plugin add 必须在 env.nu 中执行（先于 config.nu），
# 否则 config.nu 中的 plugin use 找不到 registry 会中断整个 config.nu 加载

let bin = ($nu.current-exe | path dirname)

# PATH 可能是字符串（从 MCP env 传入）或列表（nushell 原生）
# 需要先统一为列表，否则外部命令查找失败
let path_list = if ($env.PATH | describe) =~ 'string' {
  $env.PATH | split row (char esep)
} else {
  $env.PATH | default []
}

$env.NU_PLUGIN_DIRS = ($env.NU_PLUGIN_DIRS? | default [] | append $bin)
$env.PATH = ($path_list | append $bin)

# Skills 模块路径 — 让 use skills/xxx 在 MCP evaluate 中可解析
# Claude Code skills 安装在 ~/.claude/skills/ (getClaudeConfigHomeDir + '/skills')
# NU_LIB_DIRS 搜索规则：use skills/xxx → 在每个条目下找 skills/xxx
# 加入 ~/.claude（父目录），而非 ~/.claude/skills
let claude_home = if ($env.CLAUDE_CONFIG_DIR? | is-not-empty) {
  $env.CLAUDE_CONFIG_DIR
} else {
  let home = if ($env.HOME? | is-not-empty) { $env.HOME } else { $env.USERPROFILE }
  [$home .claude] | path join
}
if ($claude_home | path join "skills" | path type) == dir {
  $env.NU_LIB_DIRS = ($env.NU_LIB_DIRS | default [] | append $claude_home)
}

# 注册 bin/ 下所有 nu_plugin_* 二进制（幂等，重复执行不产生重复条目）
for p in (ls $bin | where name =~ 'nu_plugin_' | get name) {
  plugin add $p
}
