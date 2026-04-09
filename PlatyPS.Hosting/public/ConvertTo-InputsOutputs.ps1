function ConvertTo-InputsOutputs {
    <#
    .SYNOPSIS
        Renders an INPUTS or OUTPUTS section as HTML.

    .DESCRIPTION
        Produces a styled <section> containing one entry per input or output type, with
        the typename displayed in a <code> element and the description in a <p> tag.
        Emits a section containing "None" when the list is empty or null.

    .PARAMETER SectionTitle
        The display title for the section, for example 'INPUTS' or 'OUTPUTS'.

    .PARAMETER SectionId
        The HTML id attribute for the <section> element, for example 'inputs' or 'outputs'.

    .PARAMETER Items
        A list of InputOutput objects from the PlatyPS CommandHelp model. Accepts the
        Inputs or Outputs property of a CommandHelp object.

    .EXAMPLE
        ```powershell
        $importParams = @{
            Path = '.\docs\MyModule\Get-Widget.md'
        }
        $help = Import-MarkdownCommandHelp @importParams
        $inputsParams = @{
            SectionTitle = 'INPUTS'
            SectionId    = 'inputs'
            Items        = $help.Inputs
        }
        ConvertTo-InputsOutputs @inputsParams
        ```

        Returns an HTML INPUTS section for the Get-Widget command.
    #>
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
