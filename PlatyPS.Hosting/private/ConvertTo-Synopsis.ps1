function ConvertTo-Synopsis {
    param([Microsoft.PowerShell.PlatyPS.Model.CommandHelp]$Help)
    Write-Section -Title 'SYNOPSIS' -Content "<p>$(ConvertTo-HtmlEncoded $Help.Synopsis)</p>"
}
