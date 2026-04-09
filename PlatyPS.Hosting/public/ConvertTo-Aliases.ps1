function ConvertTo-Aliases {
    <#
    .SYNOPSIS
        Renders the aliases for a command as an HTML section.

    .DESCRIPTION
        Accepts a PlatyPS CommandHelp model object and returns an HTML <section> block
        containing a <ul> list of <code>-wrapped alias names. Returns an empty string
        if the command has no aliases defined.

    .PARAMETER Help
        The PlatyPS CommandHelp model object to extract alias information from.

    .EXAMPLE
        ```powershell
        $importParams = @{
            Path = '.\docs\MyModule\Get-Widget.md'
        }
        $help = Import-MarkdownCommandHelp @importParams
        ConvertTo-Aliases -Help $help
        ```

        Returns an HTML aliases section for the Get-Widget command.
    #>
    [CmdletBinding(HelpUri = 'https://steviecoaster.github.io/PlatyPS.Hosting/PlatyPS.Hosting/ConvertTo-Aliases/')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [Microsoft.PowerShell.PlatyPS.Model.CommandHelp]
        $Help
    )
    if (-not $Help.Aliases -or $Help.Aliases.Count -eq 0) { return '' }

    $items = $Help.Aliases | ForEach-Object { "<li><code>$(ConvertTo-HtmlEncoded $_)</code></li>" }
    Write-Section -Title 'ALIASES' -Id 'aliases' -Content "<ul>$($items -join '')</ul>"
}
