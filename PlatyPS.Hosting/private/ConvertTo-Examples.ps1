function ConvertTo-Examples {
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
