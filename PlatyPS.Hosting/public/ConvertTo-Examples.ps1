function ConvertTo-Examples {
    <#
    .SYNOPSIS
        Renders the examples for a command as an HTML section.

    .DESCRIPTION
        Accepts a PlatyPS CommandHelp model object and returns an HTML <section> block
        containing each example as an <article> with an <h3> title and rendered
        code/prose blocks produced by ConvertTo-CodeBlock. Returns an empty string
        if the command has no examples defined.

    .PARAMETER Help
        The PlatyPS CommandHelp model object to extract examples from.

    .EXAMPLE
        ```powershell
        $importParams = @{
            Path = '.\docs\MyModule\Get-Widget.md'
        }
        $help = Import-MarkdownCommandHelp @importParams
        ConvertTo-Examples -Help $help
        ```

        Returns an HTML examples section for the Get-Widget command.
    #>
    param([Microsoft.PowerShell.PlatyPS.Model.CommandHelp]$Help)
    if (-not $Help.Examples -or $Help.Examples.Count -eq 0) { return '' }

    $exBlocks = foreach ($ex in $Help.Examples) {
        $title   = ConvertTo-HtmlEncoded $ex.Title
        $remarks = ConvertTo-CodeBlock   $ex.Remarks
        @"
            <article class="example">
                <h3>$title</h3>
                $remarks
            </article>
"@
    }
    Write-Section -Title 'EXAMPLES' -Content ($exBlocks -join "`n")
}
