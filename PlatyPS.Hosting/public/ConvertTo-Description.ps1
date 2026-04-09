function ConvertTo-Description {
    <#
    .SYNOPSIS
        Renders the description for a command as an HTML section.

    .DESCRIPTION
        Accepts a PlatyPS CommandHelp model object and returns an HTML <section> block
        containing <p> tags, one per paragraph in the description text. Returns an empty
        string if the command has no description.

    .PARAMETER Help
        The PlatyPS CommandHelp model object to extract the description from.

    .EXAMPLE
        ```powershell
        $importParams = @{
            Path = '.\docs\MyModule\Get-Widget.md'
        }
        $help = Import-MarkdownCommandHelp @importParams
        ConvertTo-Description -Help $help
        ```

        Returns an HTML description section for the Get-Widget command.
    #>
    [CmdletBinding(HelpUri = 'https://steviecoaster.github.io/PlatyPS.Hosting/PlatyPS.Hosting/ConvertTo-Description/')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [Microsoft.PowerShell.PlatyPS.Model.CommandHelp]
        $Help
    )
    if (-not $Help.Description) { return '' }
    $paras = ($Help.Description -split '\r?\n\r?\n') |
             Where-Object { $_ -match '\S' } |
             ForEach-Object { "<p>$(ConvertTo-HtmlEncoded ($_.Trim()))</p>" }
    Write-Section -Title 'DESCRIPTION' -Content ($paras -join "`n")
}
