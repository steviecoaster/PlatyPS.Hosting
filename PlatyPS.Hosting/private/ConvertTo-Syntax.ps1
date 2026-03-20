function ConvertTo-Syntax {
    param([Microsoft.PowerShell.PlatyPS.Model.CommandHelp]$Help)
    if (-not $Help.Syntax -or $Help.Syntax.Count -eq 0) { return '' }

    $blocks = foreach ($syntaxItem in $Help.Syntax) {
        $label = ConvertTo-HtmlEncoded $syntaxItem.ParameterSetName
        $code  = ConvertTo-HtmlEncoded $syntaxItem.ToString()
        @"
            <h3>$label</h3>
            <pre><code class="language-powershell">$code</code></pre>
"@
    }
    Write-Section -Title 'SYNTAX' -Content ($blocks -join "`n")
}
