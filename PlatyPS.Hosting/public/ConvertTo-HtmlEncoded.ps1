function ConvertTo-HtmlEncoded {
    <#
    .SYNOPSIS
        HTML-encodes a string by replacing special characters with HTML entities.

    .DESCRIPTION
        Replaces the characters &, <, >, and " with &amp;, &lt;, &gt;, and &quot;
        respectively. Returns an empty string when passed null or empty input.
        Used throughout the module to safely embed arbitrary text in HTML output.

    .PARAMETER Text
        The string to HTML-encode.

    .EXAMPLE
        ```powershell
        ConvertTo-HtmlEncoded -Text '<script>alert("xss")</script>'
        ```

        Returns &lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;.
    #>
    param([string]$Text)
    if (-not $Text) { return '' }
    $Text -replace '&','&amp;' `
          -replace '<','&lt;'  `
          -replace '>','&gt;'  `
          -replace '"','&quot;'
}
