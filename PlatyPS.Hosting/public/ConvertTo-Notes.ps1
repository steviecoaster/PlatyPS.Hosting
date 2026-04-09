function ConvertTo-Notes {
    <#
    .SYNOPSIS
        Renders the NOTES section of a command as an HTML section.

    .DESCRIPTION
        Accepts a PlatyPS CommandHelp model object and returns an HTML <section> block
        with each non-blank line of the notes text wrapped in a <p> tag. Returns an
        empty string if the command has no notes.

    .PARAMETER Help
        The PlatyPS CommandHelp model object to extract notes from.

    .EXAMPLE
        ```powershell
        $importParams = @{
            Path = '.\docs\MyModule\Get-Widget.md'
        }
        $help = Import-MarkdownCommandHelp @importParams
        ConvertTo-Notes -Help $help
        ```

        Returns an HTML notes section for the Get-Widget command.
    #>
    param([Microsoft.PowerShell.PlatyPS.Model.CommandHelp]$Help)
    if (-not $Help.Notes) { return '' }
    $note = ($Help.Notes -split '\r?\n') |
            Where-Object { $_ -match '\S' } |
            ForEach-Object { "<p>$(ConvertTo-HtmlEncoded $_)</p>" }
    Write-Section -Title 'NOTES' -Content ($note -join "`n")
}
