function ConvertTo-CodeBlock {
    <#
    Wraps fenced code-block text in a <pre><code> element.
    PlatyPS stores example Remarks as markdown, which can contain fenced
    ```powershell … ``` blocks.  This function extracts those blocks and
    wraps the rest as plain paragraphs.
    #>
    param([string]$Markdown)
    if (-not $Markdown) { return '' }

    $html    = [System.Text.StringBuilder]::new()
    $lines   = $Markdown -split '\r?\n'
    $inCode  = $false
    $codeBuf = [System.Text.StringBuilder]::new()

    foreach ($line in $lines) {
        if (-not $inCode -and $line -match '^\s*```') {
            $inCode = $true
            $null = $codeBuf.Clear()
            continue
        }
        if ($inCode -and $line -match '^\s*```') {
            $inCode = $false
            $null = $html.AppendLine("<pre><code class=`"language-powershell`">$(ConvertTo-HtmlEncoded $codeBuf.ToString().TrimEnd())</code></pre>")
            continue
        }
        if ($inCode) {
            $null = $codeBuf.AppendLine($line)
        }
        else {
            $encoded = ConvertTo-HtmlEncoded $line
            if ($encoded -match '\S') {
                $null = $html.AppendLine("<p>$encoded</p>")
            }
        }
    }

    # flush any unclosed code block
    if ($inCode -and $codeBuf.Length -gt 0) {
        $null = $html.AppendLine("<pre><code class=`"language-powershell`">$(ConvertTo-HtmlEncoded $codeBuf.ToString().TrimEnd())</code></pre>")
    }

    return $html.ToString()
}
