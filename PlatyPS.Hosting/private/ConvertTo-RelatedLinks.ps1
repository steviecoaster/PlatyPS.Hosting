function ConvertTo-RelatedLinks {
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
