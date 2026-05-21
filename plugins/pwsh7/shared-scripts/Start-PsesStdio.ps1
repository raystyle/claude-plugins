$ErrorActionPreference = 'Stop'

$module = Get-Module -ListAvailable PowerShellEditorServices |
    Sort-Object Version -Descending |
    Select-Object -First 1

if (-not $module) {
    throw 'PowerShellEditorServices is not installed. Run: Install-Module PowerShellEditorServices -Scope CurrentUser'
}

Import-Module $module.Path

$logPath = Join-Path ([System.IO.Path]::GetTempPath()) 'PSES-Claude.log'

Start-EditorServices `
    -HostName 'Claude Code' `
    -HostProfileId 'ClaudeCode' `
    -HostVersion '1.0.0' `
    -Stdio `
    -BundledModulesPath (Join-Path (Split-Path $module.Path) 'bin') `
    -LogPath $logPath `
    -LogLevel 'Error' `
    -LanguageServiceOnly
