function ConvertTo-InputsOutputs {
    param(
        [string] $SectionTitle,
        [string] $SectionId,
        $Items    # List[InputOutput]
    )
    if (-not $Items -or $Items.Count -eq 0) {
        return Write-Section -Title $SectionTitle -Id $SectionId -Content '<p>None</p>'
    }

    $blocks = foreach ($io in $Items) {
        @"
            <section class="io-type">
                <h3><code>$(ConvertTo-HtmlEncoded $io.Typename)</code></h3>
                <p>$(ConvertTo-HtmlEncoded $io.Description)</p>
            </section>
"@
    }
    Write-Section -Title $SectionTitle -Id $SectionId -Content ($blocks -join "`n")
}
