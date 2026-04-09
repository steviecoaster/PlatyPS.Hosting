function ConvertTo-RelatedLinks {
    <#
    .SYNOPSIS
        Renders the related links for a command as an HTML section.

    .DESCRIPTION
        Accepts a PlatyPS CommandHelp model object and returns an HTML <section> block
        containing a <ul> list of anchor tags for each related link. Links with no URI
        are rendered as plain text list items. Returns an empty string if the command
        has no related links defined.

    .PARAMETER Help
        The PlatyPS CommandHelp model object to extract related links from.

    .EXAMPLE
        ```powershell
        $importParams = @{
            Path = '.\docs\MyModule\Get-Widget.md'
        }
        $help = Import-MarkdownCommandHelp @importParams
        ConvertTo-RelatedLinks -Help $help
        ```

        Returns an HTML related links section for the Get-Widget command.
    #>
    param([Microsoft.PowerShell.PlatyPS.Model.CommandHelp]$Help)
    if (-not $Help.RelatedLinks -or $Help.RelatedLinks.Count -eq 0) { return '' }

    $links = foreach ($link in $Help.RelatedLinks) {
        $text = ConvertTo-HtmlEncoded ($link.LinkText -or $link.Uri)
        $href = ConvertTo-HtmlEncoded $link.Uri
        if ($href) {
            "<li><a href=`"$href`">$text</a></li>"
        } else {
            "<li>$text</li>"
        }
    }
    Write-Section -Title 'RELATED LINKS' -Id 'related-links' -Content "<ul>$($links -join '')</ul>"
}
