function ConvertTo-HtmlEncoded {
    param([string]$Text)
    if (-not $Text) { return '' }
    $Text -replace '&','&amp;' `
          -replace '<','&lt;'  `
          -replace '>','&gt;'  `
          -replace '"','&quot;'
}
