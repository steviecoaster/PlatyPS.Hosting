function ConvertTo-Synopsis {
    <#
    .SYNOPSIS
        Renders the SYNOPSIS section of a command as HTML.

    .DESCRIPTION
        Accepts a PlatyPS CommandHelp model object and returns an HTML <section> block
        containing a single <p> element with the command's synopsis text.

    .PARAMETER Help
        The PlatyPS CommandHelp model object to extract the synopsis from.

    .EXAMPLE
        ```powershell
        $importParams = @{
            Path = '.\docs\MyModule\Get-Widget.md'
        }
        $help = Import-MarkdownCommandHelp @importParams
        ConvertTo-Synopsis -Help $help
        ```

        Returns an HTML synopsis section for the Get-Widget command.
    #>
    param([Microsoft.PowerShell.PlatyPS.Model.CommandHelp]$Help)
    Write-Section -Title 'SYNOPSIS' -Content "<p>$(ConvertTo-HtmlEncoded $Help.Synopsis)</p>"
}
