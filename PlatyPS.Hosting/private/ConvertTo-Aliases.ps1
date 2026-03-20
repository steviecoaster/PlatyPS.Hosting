function ConvertTo-Aliases {
    param([Microsoft.PowerShell.PlatyPS.Model.CommandHelp]$Help)
    if (-not $Help.Aliases -or $Help.Aliases.Count -eq 0) { return '' }

    $items = $Help.Aliases | ForEach-Object { "<li><code>$(ConvertTo-HtmlEncoded $_)</code></li>" }
    Write-Section -Title 'ALIASES' -Id 'aliases' -Content "<ul>$($items -join '')</ul>"
}
