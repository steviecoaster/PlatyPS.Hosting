function ConvertTo-Syntax {
    <#
    .SYNOPSIS
        Renders the SYNTAX section of a command as HTML.

    .DESCRIPTION
        Accepts a PlatyPS CommandHelp model object and returns an HTML <section> block
        containing one <h3> heading and <pre><code class="language-powershell"> block per
        parameter set. Returns an empty string if the command has no syntax entries.

    .PARAMETER Help
        The PlatyPS CommandHelp model object to extract syntax information from.

    .EXAMPLE
        ```powershell
        $importParams = @{
            Path = '.\docs\MyModule\Get-Widget.md'
        }
        $help = Import-MarkdownCommandHelp @importParams
        ConvertTo-Syntax -Help $help
        ```

        Returns an HTML syntax section for the Get-Widget command.
    #>
    [CmdletBinding(HelpUri = 'https://steviecoaster.github.io/PlatyPS.Hosting/PlatyPS.Hosting/ConvertTo-Syntax/')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [Microsoft.PowerShell.PlatyPS.Model.CommandHelp]
        $Help
    )
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
