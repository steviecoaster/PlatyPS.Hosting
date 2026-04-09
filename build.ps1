[CmdletBinding()]
Param(
    [Parameter()]
    [String]
    $ScriptModule = (Join-Path $PSScriptRoot 'PlatyPS.Hosting.psm1')
)

if (Test-Path $ScriptModule) {
    Remove-Item $ScriptModule -Force
}

Get-ChildItem (Join-Path $PSScriptRoot 'PlatyPS.Hosting' 'public')  -Filter *.ps1 | ForEach-Object {
    $content = Get-Content $_.FullName -Raw

    "$content" | Add-Content -Path $ScriptModule
}