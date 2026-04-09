function ConvertTo-CodeBlock {
    <#
    .SYNOPSIS
        Converts markdown fenced code blocks to HTML <pre><code> elements.

    .DESCRIPTION
        Parses a markdown string for fenced blocks and converts each block to a
        <pre><code class="language-powershell"> HTML element. Text outside of fenced
        blocks that contains non-whitespace characters is wrapped in <p> tags. Any
        unclosed fenced block at end of input is flushed as a code element.

        PlatyPS stores example Remarks as markdown which can contain fenced
        powershell blocks - this function handles that conversion.

    .PARAMETER Markdown
        A markdown string to parse, typically the Remarks property of a PlatyPS example.

    .EXAMPLE
        ```powershell
        $importParams = @{
            Path = '.\docs\MyModule\Get-Widget.md'
        }
        $help = Import-MarkdownCommandHelp @importParams
        ConvertTo-CodeBlock -Markdown $help.Examples[0].Remarks
        ```

        Converts the fenced PowerShell code in the first example's Remarks to HTML.
    #>
    [CmdletBinding(HelpUri = 'https://steviecoaster.github.io/PlatyPS.Hosting/PlatyPS.Hosting/ConvertTo-CodeBlock/')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Markdown
    )
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
