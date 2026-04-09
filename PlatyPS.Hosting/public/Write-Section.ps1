function Write-Section {
    <#
    .SYNOPSIS
        Wraps HTML content in a styled <section> element.

    .DESCRIPTION
        Returns a <section> element with an id attribute and an <h2> heading, followed
        by the provided content string. The id defaults to the lowercased, hyphenated
        form of Title when not explicitly supplied. Used internally by all ConvertTo-*
        renderers to produce consistently structured HTML sections.

    .PARAMETER Title
        The text for the <h2> heading and the basis of the default id attribute.

    .PARAMETER Content
        The HTML content to place inside the <section>, after the heading.

    .PARAMETER Id
        The HTML id attribute value for the <section> element. Defaults to Title
        converted to lowercase with spaces replaced by hyphens.

    .EXAMPLE
        ```powershell
        $sectionParams = @{
            Title   = 'SYNOPSIS'
            Content = '<p>Gets a widget from the widget store.</p>'
        }
        Write-Section @sectionParams
        ```

        Returns a <section id="synopsis"> element with a SYNOPSIS heading and the
        provided paragraph as content.
    #>
    param(
        [string] $Title,
        [string] $Content,
        [string] $Id = ($Title.ToLower() -replace '\s','-')
    )
    @"
        <section id="$Id">
            <h2>$Title</h2>
            $Content
        </section>
"@
}
