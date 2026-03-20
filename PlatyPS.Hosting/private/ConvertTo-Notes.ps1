function ConvertTo-Notes {
    param([Microsoft.PowerShell.PlatyPS.Model.CommandHelp]$Help)
    if (-not $Help.Notes) { return '' }
    $note = ($Help.Notes -split '\r?\n') |
            Where-Object { $_ -match '\S' } |
            ForEach-Object { "<p>$(ConvertTo-HtmlEncoded $_)</p>" }
    Write-Section -Title 'NOTES' -Content ($note -join "`n")
}
