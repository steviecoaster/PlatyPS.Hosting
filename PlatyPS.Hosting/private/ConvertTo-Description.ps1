function ConvertTo-Description {
    param([Microsoft.PowerShell.PlatyPS.Model.CommandHelp]$Help)
    if (-not $Help.Description) { return '' }
    $paras = ($Help.Description -split '\r?\n\r?\n') |
             Where-Object { $_ -match '\S' } |
             ForEach-Object { "<p>$(ConvertTo-HtmlEncoded ($_.Trim()))</p>" }
    Write-Section -Title 'DESCRIPTION' -Content ($paras -join "`n")
}
