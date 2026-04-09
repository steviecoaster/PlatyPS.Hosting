function ConvertTo-Aliases {
    <#
    .SYNOPSIS
        Renders the aliases for a command as an HTML section.

    .DESCRIPTION
        Accepts a PlatyPS CommandHelp model object and returns an HTML <section> block
        containing a <ul> list of <code>-wrapped alias names. Returns an empty string
        if the command has no aliases defined.

    .PARAMETER Help
        The PlatyPS CommandHelp model object to extract alias information from.

    .EXAMPLE
        ```powershell
        $importParams = @{
            Path = '.\docs\MyModule\Get-Widget.md'
        }
        $help = Import-MarkdownCommandHelp @importParams
        ConvertTo-Aliases -Help $help
        ```

        Returns an HTML aliases section for the Get-Widget command.
    #>
    param([Microsoft.PowerShell.PlatyPS.Model.CommandHelp]$Help)
    if (-not $Help.Aliases -or $Help.Aliases.Count -eq 0) { return '' }

    $items = $Help.Aliases | ForEach-Object { "<li><code>$(ConvertTo-HtmlEncoded $_)</code></li>" }
    Write-Section -Title 'ALIASES' -Id 'aliases' -Content "<ul>$($items -join '')</ul>"
}

function ConvertTo-CodeBlock {
    <#
    .SYNOPSIS
        Converts markdown fenced code blocks to HTML <pre><code> elements.

    .DESCRIPTION
        Parses a markdown string for fenced blocks and converts each block to a
        <pre><code class="language-powershell"> HTML element. Text outside of fenced
        blocks that contains non-whitespace characters is wrapped in <p> tags. Any
        unclosed fenced block at end of input is flushed as a code element.

        PlatyPS stores example Remarks as markdown which can contain fenced
        powershell blocks - this function handles that conversion.

    .PARAMETER Markdown
        A markdown string to parse, typically the Remarks property of a PlatyPS example.

    .EXAMPLE
        ```powershell
        $importParams = @{
            Path = '.\docs\MyModule\Get-Widget.md'
        }
        $help = Import-MarkdownCommandHelp @importParams
        ConvertTo-CodeBlock -Markdown $help.Examples[0].Remarks
        ```

        Converts the fenced PowerShell code in the first example's Remarks to HTML.
    #>
    param([string]$Markdown)
    if (-not $Markdown) { return '' }

    $html    = [System.Text.StringBuilder]::new()
    $lines   = $Markdown -split '\r?\n'
    $inCode  = $false
    $codeBuf = [System.Text.StringBuilder]::new()

    foreach ($line in $lines) {
        if (-not $inCode -and $line -match '^\s*```') {
            $inCode = $true
            $null = $codeBuf.Clear()
            continue
        }
        if ($inCode -and $line -match '^\s*```') {
            $inCode = $false
            $null = $html.AppendLine("<pre><code class=`"language-powershell`">$(ConvertTo-HtmlEncoded $codeBuf.ToString().TrimEnd())</code></pre>")
            continue
        }
        if ($inCode) {
            $null = $codeBuf.AppendLine($line)
        }
        else {
            $encoded = ConvertTo-HtmlEncoded $line
            if ($encoded -match '\S') {
                $null = $html.AppendLine("<p>$encoded</p>")
            }
        }
    }

    # flush any unclosed code block
    if ($inCode -and $codeBuf.Length -gt 0) {
        $null = $html.AppendLine("<pre><code class=`"language-powershell`">$(ConvertTo-HtmlEncoded $codeBuf.ToString().TrimEnd())</code></pre>")
    }

    return $html.ToString()
}

function ConvertTo-Description {
    <#
    .SYNOPSIS
        Renders the description for a command as an HTML section.

    .DESCRIPTION
        Accepts a PlatyPS CommandHelp model object and returns an HTML <section> block
        containing <p> tags, one per paragraph in the description text. Returns an empty
        string if the command has no description.

    .PARAMETER Help
        The PlatyPS CommandHelp model object to extract the description from.

    .EXAMPLE
        ```powershell
        $importParams = @{
            Path = '.\docs\MyModule\Get-Widget.md'
        }
        $help = Import-MarkdownCommandHelp @importParams
        ConvertTo-Description -Help $help
        ```

        Returns an HTML description section for the Get-Widget command.
    #>
    param([Microsoft.PowerShell.PlatyPS.Model.CommandHelp]$Help)
    if (-not $Help.Description) { return '' }
    $paras = ($Help.Description -split '\r?\n\r?\n') |
             Where-Object { $_ -match '\S' } |
             ForEach-Object { "<p>$(ConvertTo-HtmlEncoded ($_.Trim()))</p>" }
    Write-Section -Title 'DESCRIPTION' -Content ($paras -join "`n")
}

function ConvertTo-Examples {
    <#
    .SYNOPSIS
        Renders the examples for a command as an HTML section.

    .DESCRIPTION
        Accepts a PlatyPS CommandHelp model object and returns an HTML <section> block
        containing each example as an <article> with an <h3> title and rendered
        code/prose blocks produced by ConvertTo-CodeBlock. Returns an empty string
        if the command has no examples defined.

    .PARAMETER Help
        The PlatyPS CommandHelp model object to extract examples from.

    .EXAMPLE
        ```powershell
        $importParams = @{
            Path = '.\docs\MyModule\Get-Widget.md'
        }
        $help = Import-MarkdownCommandHelp @importParams
        ConvertTo-Examples -Help $help
        ```

        Returns an HTML examples section for the Get-Widget command.
    #>
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

function ConvertTo-HugoFormat {
    <#
    .SYNOPSIS
        Converts PlatyPS-generated Markdown files to Hugo-compatible format.

    .DESCRIPTION
        ConvertTo-HugoFormat reads PlatyPS Markdown files and rewrites them with:

        - Hugo front matter (title, weight) replacing PlatyPS YAML metadata
        - Module index pages renamed to _index.md (Hugo branch bundle convention)
        - SYNTAX section cleaned up (removes __AllParameterSets subheading)
        - ALIASES section cleaned up (removes unresolved {{...}} placeholders)
        - Optional root content/_index.md generated from the module page (-RootIndex)

        The output is ready to drop into a Hugo content directory. Module pages
        receive chapter: true so the Relearn theme treats them as section headings.

    .PARAMETER Path
        Path to one or more PlatyPS Markdown files, or a directory containing them.
        Accepts pipeline input.

    .PARAMETER OutputFolder
        Destination folder for the converted files. Created automatically if it
        does not exist.

    .PARAMETER RootIndex
        When processing a directory, also generate a root content/_index.md one
        level above OutputFolder. The file is built from the module page title,
        description, and the synopsis of each cmdlet page. Has no effect when
        processing individual files.

    .PARAMETER Force
        Overwrite existing output files without prompting.

    .PARAMETER PassThru
        Emit the generated FileInfo objects to the pipeline.

    .EXAMPLE
        ```powershell
        $hugoParams = @{
            Path         = '.\help\markdown\PlatyPS.Hosting'
            OutputFolder = '.\hugo\content\PlatyPS.Hosting'
            RootIndex    = $true
        }
        ConvertTo-HugoFormat @hugoParams
        ```

        Converts all PlatyPS Markdown files and also generates .\hugo\content\_index.md
        from the module description and cmdlet synopses.

    .EXAMPLE
        ```powershell
        Get-Item .\help\markdown\MyModule\New-Widget.md |
            ConvertTo-HugoFormat -OutputFolder .\hugo\content\MyModule -PassThru
        ```

        Converts a single file and returns the resulting FileInfo to the pipeline.
    #>
    [CmdletBinding(HelpUri = 'https://steviecoaster.github.io/PlatyPS.Hosting/PlatyPS.Hosting/ConvertTo-HugoFormat',SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [string[]]
        $Path,

        [Parameter(Mandatory)]
        [string]
        $OutputFolder,

        [switch]
        $Force,

        [switch]
        $RootIndex,

        [switch]
        $PassThru
    )

    begin {
        if (-not (Test-Path $OutputFolder)) {
            $null = New-Item $OutputFolder -ItemType Directory -Force
        }

        # Cmdlet pages start at weight 2; module page is always weight 1
        $weight = 2

        # Accumulated data for optional root _index.md
        $rootModuleTitle       = $null
        $rootModuleDescription = $null
        $rootCmdletRows        = [System.Collections.Generic.List[string]]::new()
    }

    process {
        foreach ($p in $Path) {
            $resolved = Get-Item -LiteralPath $p -ErrorAction Stop

            $files = if ($resolved.PSIsContainer) {
                Get-ChildItem -LiteralPath $resolved.FullName -Filter '*.md'
            }
            else {
                $resolved
            }

            foreach ($file in $files) {
                $raw = Get-Content -LiteralPath $file.FullName -Raw

                # Split YAML front matter from body
                if ($raw -notmatch '(?s)\A---\r?\n(.+?)\r?\n---\r?\n(.*)') {
                    Write-Warning "Skipping $($file.Name): no YAML front matter found."
                    continue
                }

                $yamlBlock = $Matches[1]
                $body      = $Matches[2]

                # Extract the fields we need from PlatyPS front matter
                $docType = if ($yamlBlock -match '(?m)^document type:\s*(.+)$') { $Matches[1].Trim() } else { 'cmdlet' }
                $title   = if ($yamlBlock -match '(?m)^title:\s*(.+)$')         { $Matches[1].Trim() } else { $file.BaseName }

                # Build Hugo front matter
                $isModule = $docType -eq 'module'

                $hugoFrontMatter = if ($isModule) {
                    @"
---
title: "$title"
weight: 1
chapter: true
---
"@
                }
                else {
                    $fm = @"
---
title: "$title"
weight: $weight
---
"@
                    $weight++
                    $fm
                }

                # Remove ### __AllParameterSets subheading from SYNTAX section
                $body = $body -replace '(?m)^### __AllParameterSets\r?\n', ''

                # Replace the unresolved PlatyPS alias placeholder with "None"
                $body = $body -replace '(?m)^This cmdlet has the following aliases,\r?\n\s*\{\{Insert list of aliases\}\}', 'None'

                # Collect data for optional root _index.md
                if ($RootIndex -and $resolved.PSIsContainer) {
                    if ($isModule) {
                        $rootModuleTitle = $title
                        # Grab the Description body (text between ## Description and the next ##)
                        if ($body -match '(?s)## Description\r?\n\r?\n(.+?)(?=\r?\n## |\z)') {
                            $rootModuleDescription = $Matches[1].Trim()
                        }
                    }
                    else {
                        # Grab synopsis (first non-blank line after ## SYNOPSIS)
                        $synopsis = if ($body -match '(?m)^## SYNOPSIS\r?\n\r?\n(.+)$') { $Matches[1].Trim() } else { '' }
                        $sectionName = Split-Path $OutputFolder -Leaf
                        $rootCmdletRows.Add("| [$title]($sectionName/$title) | $synopsis |")
                    }
                }

                # Determine output filename
                $outName = if ($isModule) { '_index.md' } else { $file.Name }
                $outPath = Join-Path $OutputFolder $outName

                if ((Test-Path $outPath) -and -not $Force) {
                    Write-Warning "Skipping existing file (use -Force to overwrite): $outPath"
                    continue
                }

                if ($PSCmdlet.ShouldProcess($outPath, 'Write Hugo Markdown')) {
                    ($hugoFrontMatter + "`n" + $body.TrimStart()) |
                        Set-Content -LiteralPath $outPath -Encoding utf8NoBOM

                    if ($PassThru) {
                        Get-Item -LiteralPath $outPath
                    }
                }
            }
        }
    }

    end {
        if (-not $RootIndex -or -not $rootModuleTitle) { return }

        $siteContentRoot = Split-Path $OutputFolder -Parent
        $rootIndexPath   = Join-Path $siteContentRoot '_index.md'

        if ((Test-Path $rootIndexPath) -and -not $Force) {
            Write-Warning "Skipping existing root index (use -Force to overwrite): $rootIndexPath"
            return
        }

        $cmdletTable = @(
            '| Command | Description |'
            '|---------|-------------|'
        ) + $rootCmdletRows | Out-String -Width 9999

        $rootContent = @"
---
title: "$rootModuleTitle"
weight: 1
---

$rootModuleDescription

## Commands

$($cmdletTable.Trim())
"@

        if ($PSCmdlet.ShouldProcess($rootIndexPath, 'Write Hugo root _index.md')) {
            $rootContent | Set-Content -LiteralPath $rootIndexPath -Encoding utf8NoBOM

            if ($PassThru) {
                Get-Item -LiteralPath $rootIndexPath
            }
        }
    }
}

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

function ConvertTo-Parameters {
    <#
    .SYNOPSIS
        Renders the parameters for a command as a detailed HTML section.

    .DESCRIPTION
        Accepts a PlatyPS CommandHelp model object and returns an HTML PARAMETERS
        <section> containing a subsection for each parameter with required/position
        badges, type, default value, aliases, accepted values, and wildcard support.
        Returns an empty string if the command has no parameters.

    .PARAMETER Help
        The PlatyPS CommandHelp model object to extract parameter information from.

    .EXAMPLE
        ```powershell
        $importParams = @{
            Path = '.\docs\MyModule\Get-Widget.md'
        }
        $help = Import-MarkdownCommandHelp @importParams
        ConvertTo-Parameters -Help $help
        ```

        Returns an HTML parameters section for the Get-Widget command.
    #>
    param([Microsoft.PowerShell.PlatyPS.Model.CommandHelp]$Help)
    if (-not $Help.Parameters -or $Help.Parameters.Count -eq 0) { return '' }

    $paramBlocks = foreach ($p in $Help.Parameters) {
        # ---- required / position badge ----
        $badges = @()
        # Check all parameter sets for Required/Position info
        foreach ($ps in $p.ParameterSets) {
            if ($ps.IsRequired) { $badges += '<span class="badge required">Required</span>' }
            if ($ps.Position -ge 0) { $badges += "<span class='badge position'>Position: $($ps.Position)</span>" }
        }
        if ($p.DontShow) { $badges += '<span class="badge dontshow">Don''t Show</span>' }
        $badgeHtml = if ($badges) { "<div class='badges'>$($badges -join ' ')</div>" } else { '' }

        # ---- meta table ----
        $metaRows = @(
            "<tr><th>Type</th><td><code>$(ConvertTo-HtmlEncoded $p.Type)</code></td></tr>"
            "<tr><th>Default Value</th><td>$(ConvertTo-HtmlEncoded $p.DefaultValue)</td></tr>"
        )
        if ($p.Aliases -and $p.Aliases.Count -gt 0) {
            $aliasText = ($p.Aliases | ForEach-Object { "<code>$_</code>" }) -join ', '
            $metaRows += "<tr><th>Aliases</th><td>$aliasText</td></tr>"
        }
        if ($p.AcceptedValues -and $p.AcceptedValues.Count -gt 0) {
            $vals = ($p.AcceptedValues | ForEach-Object { "<code>$(ConvertTo-HtmlEncoded $_)</code>" }) -join ', '
            $metaRows += "<tr><th>Accepted Values</th><td>$vals</td></tr>"
        }
        if ($p.SupportsWildcards) { $metaRows += '<tr><th>Wildcards</th><td>Yes</td></tr>' }

        @"
            <section class="parameter" id="param-$($p.Name.ToLower())">
                <h3>-$($p.Name)</h3>
                $badgeHtml
                <p>$(ConvertTo-HtmlEncoded $p.Description)</p>
                <table class="param-meta">$($metaRows -join '')</table>
            </section>
"@
    }
    Write-Section -Title 'PARAMETERS' -Content ($paramBlocks -join "`n")
}

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

function ConvertTo-Syntax {
    <#
    .SYNOPSIS
        Renders the SYNTAX section of a command as HTML.

    .DESCRIPTION
        Accepts a PlatyPS CommandHelp model object and returns an HTML <section> block
        containing one <h3> heading and <pre><code class="language-powershell"> block per
        parameter set. Returns an empty string if the command has no syntax entries.

    .PARAMETER Help
        The PlatyPS CommandHelp model object to extract syntax information from.

    .EXAMPLE
        ```powershell
        $importParams = @{
            Path = '.\docs\MyModule\Get-Widget.md'
        }
        $help = Import-MarkdownCommandHelp @importParams
        ConvertTo-Syntax -Help $help
        ```

        Returns an HTML syntax section for the Get-Widget command.
    #>
    param([Microsoft.PowerShell.PlatyPS.Model.CommandHelp]$Help)
    if (-not $Help.Syntax -or $Help.Syntax.Count -eq 0) { return '' }

    $blocks = foreach ($syntaxItem in $Help.Syntax) {
        $label = ConvertTo-HtmlEncoded $syntaxItem.ParameterSetName
        $code  = ConvertTo-HtmlEncoded $syntaxItem.ToString()
        @"
            <h3>$label</h3>
            <pre><code class="language-powershell">$code</code></pre>
"@
    }
    Write-Section -Title 'SYNTAX' -Content ($blocks -join "`n")
}

function Export-HtmlCommandHelp {
    <#
.SYNOPSIS
    Custom HTML renderer for PlatyPS CommandHelp objects.

.DESCRIPTION
    Demonstrates how to build a custom renderer using the PlatyPS v1 object model.
    PlatyPS ships built-in renderers for Markdown, YAML, and MAML.  This script
    shows how to consume CommandHelp objects straight off the pipeline and emit
    any arbitrary output format – in this case self-contained HTML files that match
    what Get-Help would display, but in a browser-friendly layout.

    Pipeline pattern (mirrors the built-in Export-* cmdlets):

        # From live reflection
        New-CommandHelp -CommandInfo (Get-Command -Module MyModule) |
            Export-HtmlCommandHelp -OutputFolder .\html

        # From existing Markdown
        Measure-PlatyPSMarkdown -Path .\docs\*.md |
            Where-Object Filetype -match 'CommandHelp' |
            Import-MarkdownCommandHelp -Path { $_.FilePath } |
            Export-HtmlCommandHelp -OutputFolder .\html

.PARAMETER CommandHelp
    One or more Microsoft.PowerShell.PlatyPS.Model.CommandHelp objects.
    Accepts pipeline input.

.PARAMETER OutputFolder
    Root folder for the HTML files.  A sub-folder named after the module is
    created automatically, mirroring the convention used by Export-MarkdownCommandHelp.

.PARAMETER ThemeFile
    Path to a .psd1 theme file.  Any keys present in the file override the
    built-in defaults; missing keys keep their default values.
    Copy themes\Default.psd1 from the module directory to get started.

.PARAMETER Force
    Overwrite existing files without prompting.

.PARAMETER PassThru
    Emit the generated FileInfo objects to the pipeline.

.EXAMPLE
    ```powershell
    $exportParams = @{
        OutputFolder = '.\html'
        Force        = $true
    }
    Get-Command -Module Microsoft.PowerShell.Utility |
        Select-Object -First 5 |
        New-CommandHelp |
        Export-HtmlCommandHelp @exportParams
    ```

.EXAMPLE
    ```powershell
    $exportParams = @{
        OutputFolder = '.\html'
        PassThru     = $true
    }
    Import-MarkdownCommandHelp -Path .\docs\MyModule\Get-Widget.md |
        Export-HtmlCommandHelp @exportParams
    ```

.NOTES
#>
    [CmdletBinding(HelpUri = 'https://steviecoaster.github.io/PlatyPS.Hosting/PlatyPS.Hosting/Export-HtmlCommandHelp/',SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Microsoft.PowerShell.PlatyPS.Model.CommandHelp[]]
        $CommandHelp,

        [Parameter(Mandatory, Position = 0)]
        [string]
        $OutputFolder,

        [switch]
        $Force,

        [switch]
        $PassThru,

        [Parameter()]
        [string]
        $ThemeFile
    )

    begin {
        $resolvedOutput = $PSCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFolder)
        $theme = Resolve-HtmlTheme -ThemeFile $ThemeFile
        # Accumulate commands per module so we can build an index.html in end {}
        $commandsByModule = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[Microsoft.PowerShell.PlatyPS.Model.CommandHelp]]]::new()

    }

    process {
        # Only accumulate - generation happens in end{} so every page
        # has the full command list available for sidebar navigation.
        foreach ($ch in $CommandHelp) {
            if (-not $commandsByModule.ContainsKey($ch.ModuleName)) {
                $commandsByModule[$ch.ModuleName] = [System.Collections.Generic.List[Microsoft.PowerShell.PlatyPS.Model.CommandHelp]]::new()
            }
            $commandsByModule[$ch.ModuleName].Add($ch)
        }
    }

    end {
        foreach ($moduleName in $commandsByModule.Keys) {
            $moduleFolder = Join-Path $resolvedOutput ($moduleName -replace '[^\w\-.]', '_')

            if (-not (Test-Path $moduleFolder)) {
                if ($PSCmdlet.ShouldProcess($moduleFolder, 'Create directory')) {
                    $null = New-Item -ItemType Directory -Path $moduleFolder -Force
                }
            }

            $commands     = $commandsByModule[$moduleName].ToArray()
            $sortedNames  = $commands | Sort-Object Title | ForEach-Object { $_.Title }

            # ── Command pages ────────────────────────────────────────────────────
            foreach ($ch in $commands) {
                $filePath = Join-Path $moduleFolder "$($ch.Title).html"

                if ((Test-Path $filePath) -and -not $Force) {
                    Write-Warning "File already exists (use -Force to overwrite): $filePath"
                    continue
                }

                if ($PSCmdlet.ShouldProcess($filePath, 'Write HTML help file')) {
                    $html = New-HelpPage -Help $ch -AllCommands $sortedNames -Theme $theme
                    [System.IO.File]::WriteAllText($filePath, $html, [System.Text.Encoding]::UTF8)
                    Write-Verbose "Written: $filePath"

                    if ($PassThru) { Get-Item -LiteralPath $filePath }
                }
            }

            # ── Index page ───────────────────────────────────────────────────────
            $indexPath = Join-Path $moduleFolder 'index.html'

            if ((Test-Path $indexPath) -and -not $Force) {
                Write-Warning "Index already exists (use -Force to overwrite): $indexPath"
                continue
            }

            if ($PSCmdlet.ShouldProcess($indexPath, 'Write module index page')) {
                $indexHtml = New-ModuleIndexPage -ModuleName $moduleName -Commands $commands -Theme $theme
                [System.IO.File]::WriteAllText($indexPath, $indexHtml, [System.Text.Encoding]::UTF8)
                Write-Verbose "Written index: $indexPath"

                if ($PassThru) { Get-Item -LiteralPath $indexPath }
            }
        }
    }
}
function New-HelpPage {
    <#
    .SYNOPSIS
        Builds the complete HTML page for a single command.

    .DESCRIPTION
        Orchestrates all ConvertTo-* renderers to produce a full self-contained HTML page
        for one command, including the themed CSS variables, a page header, a sidebar with
        navigation links to other commands in the module, and all content sections such as
        synopsis, syntax, aliases, description, examples, parameters, inputs, outputs,
        notes, and related links.

    .PARAMETER Help
        The PlatyPS CommandHelp model object for the command to render.

    .PARAMETER AllCommands
        An array of command name strings used to build the sidebar navigation links.
        Defaults to an empty array when omitted.

    .PARAMETER Theme
        A hashtable of CSS variable names to values, as returned by Resolve-HtmlTheme.
        When empty or omitted, the built-in default theme is used.

    .EXAMPLE
        ```powershell
        $importParams = @{
            Path = '.\docs\MyModule\Get-Widget.md'
        }
        $help = Import-MarkdownCommandHelp @importParams
        $pageParams = @{
            Help        = $help
            AllCommands = @('Get-Widget', 'Set-Widget')
            Theme       = Resolve-HtmlTheme
        }
        New-HelpPage @pageParams
        ```

        Returns the complete HTML string for the Get-Widget command page with sidebar
        navigation and the default theme applied.
    #>
    param(
        [Microsoft.PowerShell.PlatyPS.Model.CommandHelp] $Help,
        [string[]] $AllCommands = @(),
        [hashtable] $Theme = @{}
    )

    $title     = ConvertTo-HtmlEncoded $Help.Title
    $module    = ConvertTo-HtmlEncoded $Help.ModuleName
    $dateStamp = if ($Help.Metadata -and $Help.Metadata['ms.date']) {
                     ConvertTo-HtmlEncoded $Help.Metadata['ms.date']
                 } else { (Get-Date -Format 'MM/dd/yyyy') }
    $onlineUri = if ($Help.Metadata -and $Help.Metadata['HelpUri']) { $Help.Metadata['HelpUri'] } else { '' }

    $sidebarLinks = foreach ($name in $AllCommands | Sort-Object) {
        $encodedName = ConvertTo-HtmlEncoded $name
        if ($name -eq $Help.Title) {
            "        <li class='current'>$encodedName</li>"
        } else {
            "        <li><a href='$encodedName.html'>$encodedName</a></li>"
        }
    }

    $body = @(
        ConvertTo-Synopsis        $Help
        ConvertTo-Syntax          $Help
        ConvertTo-Aliases         $Help
        ConvertTo-Description     $Help
        ConvertTo-Examples        $Help
        ConvertTo-Parameters      $Help
        ConvertTo-InputsOutputs   -SectionTitle 'INPUTS'  -SectionId 'inputs'  -Items $Help.Inputs
        ConvertTo-InputsOutputs   -SectionTitle 'OUTPUTS' -SectionId 'outputs' -Items $Help.Outputs
        ConvertTo-Notes           $Help
        ConvertTo-RelatedLinks    $Help
    ) -join "`n"

    # Build :root CSS-variable block from the resolved theme hashtable.
    # If $Theme is empty (direct call without Export-HtmlCommandHelp), fall back to defaults.
    $effectiveTheme = if ($Theme.Count -gt 0) { $Theme } else { Resolve-HtmlTheme }
    $cssVars = ($effectiveTheme.GetEnumerator() | ForEach-Object {
        "        --$($_.Key): $($_.Value);"
    }) -join "`n"

    @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title - PowerShell Help</title>
    <style>
        :root {
$cssVars
        }

        /* ---- Reset & base ---- */
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        body   { font-family: var(--font-body);
                 font-size: 16px; line-height: 1.6; color: var(--color-body-fg);
                 background: var(--color-body-bg); }
        a      { color: var(--color-link); text-decoration: none; }
        a:hover { text-decoration: underline; }
        code   { font-family: var(--font-code);
                 background: var(--color-code-bg); padding: 0.1em 0.35em; border-radius: 3px;
                 font-size: 0.9em; }
        pre    { background: var(--color-pre-bg); color: var(--color-pre-fg); padding: 1rem 1.25rem;
                 border-radius: 6px; overflow-x: auto; margin: 0.75rem 0; }
        pre code { background: none; padding: 0; font-size: 0.875rem; color: inherit; }
        p      { margin: 0.5rem 0; }
        ul     { padding-left: 1.5rem; }
        li     { margin: 0.25rem 0; }
        table  { border-collapse: collapse; width: 100%; margin: 0.5rem 0; }
        th, td { border: 1px solid var(--color-border); padding: 0.4rem 0.7rem; text-align: left; }
        th     { background: var(--color-th-bg); font-weight: 600; width: 160px; }

        /* ---- Header ---- */
        .page-header { background: var(--color-header-bg); color: var(--color-header-fg);
                       padding: 1.25rem 2rem;
                       display: flex; align-items: center; gap: 1.5rem; }
        .page-header .header-text { flex: 1; }
        .page-header .module-name { font-size: 0.875rem; opacity: 0.75; }
        .page-header h1 { font-size: 1.75rem; font-weight: 600; margin: 0.25rem 0 0; }
        .page-header .meta { font-size: 0.8rem; opacity: 0.6; margin-top: 0.4rem; }
        .page-header .home-btn { color: var(--color-header-fg);
                                 border: 1px solid var(--color-home-btn-border);
                                 padding: 0.4rem 0.9rem; border-radius: 4px;
                                 font-size: 0.875rem; white-space: nowrap;
                                 text-decoration: none; }
        .page-header .home-btn:hover { background: var(--color-home-btn-hover-bg);
                                       color: var(--color-header-fg); text-decoration: none; }

        /* ---- Two-column layout ---- */
        .layout  { display: flex; align-items: flex-start;
                   max-width: 1200px; margin: 0 auto; padding: 1.5rem; gap: 2rem; }

        /* ---- Sidebar ---- */
        .sidebar { width: 200px; flex-shrink: 0; position: sticky; top: 1rem; }
        .sidebar h2 { font-size: 0.7rem; font-weight: 700; text-transform: uppercase;
                      letter-spacing: 0.08em; color: var(--color-sidebar-label);
                      margin-bottom: 0.5rem; }
        .sidebar ul { list-style: none; padding: 0; margin: 0; }
        .sidebar li { margin: 0; }
        .sidebar li a { display: block; padding: 0.25rem 0.5rem; font-size: 0.85rem;
                        font-family: var(--font-code); color: var(--color-link);
                        border-radius: 3px; }
        .sidebar li a:hover { background: var(--color-sidebar-hover-bg); text-decoration: none; }
        .sidebar li.current { padding: 0.25rem 0.5rem; font-size: 0.85rem;
                              font-family: var(--font-code); font-weight: 700;
                              color: var(--color-sidebar-current-fg);
                              background: var(--color-sidebar-current-bg);
                              border-radius: 3px; border-left: 3px solid var(--color-accent); }

        /* ---- Main content ---- */
        main { flex: 1; min-width: 0; }

        section { margin-bottom: 2rem; }
        section h2 { font-size: 1.2rem; font-weight: 700; text-transform: uppercase;
                     letter-spacing: 0.05em; border-bottom: 2px solid var(--color-accent);
                     padding-bottom: 0.3rem; margin-bottom: 0.75rem;
                     color: var(--color-accent-dark); }
        section h3 { font-size: 1rem; font-weight: 600; margin: 1rem 0 0.4rem; color: #333; }

        /* ---- Parameters ---- */
        .parameter { border: 1px solid var(--color-border); border-radius: 6px;
                     padding: 0.75rem 1rem; margin-bottom: 1rem; background: var(--color-table-bg); }
        .parameter h3 { color: var(--color-accent); font-family: var(--font-code);
                        font-size: 1rem; }
        .badges { margin: 0.3rem 0 0.6rem; display: flex; gap: 0.4rem; flex-wrap: wrap; }
        .badge  { font-size: 0.72rem; padding: 0.15em 0.55em; border-radius: 3px;
                  font-weight: 600; text-transform: uppercase; letter-spacing: 0.04em; }
        .badge.required  { background: var(--color-badge-required-bg); color: #fff; }
        .badge.position  { background: var(--color-badge-position-bg); color: #fff; }
        .badge.dontshow  { background: var(--color-badge-dontshow-bg); color: #fff; }
        .param-meta { font-size: 0.875rem; }

        /* ---- Examples ---- */
        .example { border-left: 4px solid var(--color-accent); padding-left: 1rem;
                   margin-bottom: 1.25rem; }
        .example h3 { font-size: 0.95rem; color: var(--color-accent); }

        /* ---- IO types ---- */
        .io-type { margin-bottom: 0.75rem; }

        /* ---- Page footer ---- */
        footer { text-align: center; font-size: 0.8rem; color: var(--color-footer-fg);
                 border-top: 1px solid var(--color-border); padding: 1rem; margin-top: 3rem; }
    </style>
</head>
<body>
    <header class="page-header">
        <a href="index.html" class="home-btn">&#8962; $module</a>
        <div class="header-text">
            <div class="module-name">$module</div>
            <h1>$title</h1>
            <div class="meta">Last updated: $dateStamp$(if ($onlineUri) { " &nbsp;|&nbsp; <a href='$onlineUri' style='color:#7ac2ff'>Online version</a>" })</div>
        </div>
    </header>

    <div class="layout">
        <nav class="sidebar">
            <h2>Commands</h2>
            <ul>
$($sidebarLinks -join "`n")
            </ul>
        </nav>
        <main>
$body
        </main>
    </div>

    <footer>
        Generated by PlatyPS.Hosting &mdash; $(Get-Date -Format 'yyyy-MM-dd HH:mm')
    </footer>
</body>
</html>
"@
}

function New-ModuleHelp {
    <#
    .SYNOPSIS
        Generates all help artifacts for a loaded module in one step.

    .DESCRIPTION
        New-ModuleHelp builds three help outputs from a single reflection pass
        against a loaded module, writing each into its own sub-folder under
        OutputFolder:

        1. MAML  (<OutputFolder>\maml\<ModuleName>\)
           Updateable XML help suitable for packaging inside the module or
           distributing via Save-Help / Update-Help.  Generated with
           Export-MamlCommandHelp.

        2. Markdown  (<OutputFolder>\markdown\<ModuleName>\)
           Human-readable source files that should be kept in version control
           and hand-edited to add descriptions, examples, and notes.
           Generated with New-MarkdownCommandHelp (including a module page).
           On subsequent runs, use Update-MarkdownCommandHelp instead so that
           hand-written content is preserved.

        3. HTML  (<OutputFolder>\html\<ModuleName>\)  [optional, -Html switch]
           A static website built on top of the PlatyPS CommandHelp object
           model using the custom Export-HtmlCommandHelp renderer.  HTML is
           generated from the Markdown files rather than from live reflection,
           so hand-edited descriptions, examples, and notes are included.

    .PARAMETER ModuleName
        Name of the module to generate help for.  The module must already be
        loaded in the current session (Import-Module before calling this).

    .PARAMETER OutputFolder
        Root folder that receives the generated artifacts.  Created
        automatically if it does not yet exist.

    .PARAMETER Html
        When specified, a static HTML site is also produced in addition to
        the MAML and Markdown outputs.

    .PARAMETER ThemeFile
        Path to a .psd1 theme file passed through to Export-HtmlCommandHelp when
        -Html is specified.  Copy themes\Default.psd1 from the module directory
        as a starting point.

    .EXAMPLE
        ```powershell
        Import-Module MyModule
        $helpParams = @{
            ModuleName   = 'MyModule'
            OutputFolder = '.\docs'
        }
        New-ModuleHelp @helpParams
        ```

        Generates MAML and Markdown help for MyModule under .\docs\.

    .EXAMPLE
        ```powershell
        Import-Module PowerShellUniversal.Plaster
        $helpParams = @{
            ModuleName   = 'PowerShellUniversal.Plaster'
            OutputFolder = '.\docs'
            Html         = $true
        }
        New-ModuleHelp @helpParams
        ```

        Generates MAML, Markdown, and HTML help for the module.

    .NOTES
    #>
    [CmdletBinding(HelpUri = 'https://steviecoaster.github.io/PlatyPS.Hosting/PlatyPS.Hosting/New-ModuleHelp/')]
    Param(
        [Parameter(Mandatory)]
        [String]
        $ModuleName,

        [Parameter(Mandatory)]
        [String]
        $OutputFolder,

        [switch]
        $Html,

        [Parameter()]
        [string]
        $ThemeFile
    )
    end {
        if (-not (Test-Path $OutputFolder)) {
            $null = New-Item $OutputFolder -ItemType Directory
        }

        # Generate the CommandInfo objects via reflection
       $commands = Get-Command -Module $ModuleName |
       Where-Object { $_ -isnot [System.Management.Automation.AliasInfo]}
       $commandHelp = New-CommandHelp -CommandInfo $commands

        $exportMamlCommandHelpSplat = @{
            CommandHelp = $commandHelp
            OutputFolder = (Join-Path $OutputFolder 'maml')
        }

        # Create Maml from CommandInfo objects
        Export-MamlCommandHelp @exportMamlCommandHelpSplat

        $markdownFolder = Join-Path $OutputFolder 'markdown'
        $newMarkdownCommandHelpSplat = @{
            ModuleInfo     = Get-Module -Name $ModuleName
            OutputFolder   = $markdownFolder
            WithModulePage = $true
        }

        # Create Markdown from MAML
        New-MarkdownCommandHelp @newMarkdownCommandHelpSplat

        if ($Html) {
            Write-verbose 'Generating HTML'
            $htmlFolder = Join-Path $OutputFolder 'html'

            Measure-PlatyPSMarkdown -Path (Join-Path $markdownFolder $ModuleName '*.md') |
                Where-Object Filetype -match 'CommandHelp' |
                Import-MarkdownCommandHelp -Path { $_.FilePath } |
                # Create HTML from markdown if requested
                Export-HtmlCommandHelp -OutputFolder $htmlFolder -Force -ThemeFile $ThemeFile
        }
    }
}
function New-ModuleIndexPage {
    <#
    .SYNOPSIS
        Builds the HTML module index page for a set of commands.

    .DESCRIPTION
        Creates a self-contained HTML landing page that lists all commands from a module
        in a table with their names and synopses, plus a sidebar navigation list. The
        page uses CSS variables from the provided theme hashtable, falling back to the
        built-in default theme when none is supplied.

    .PARAMETER ModuleName
        The name of the module, displayed in the page header and title.

    .PARAMETER Commands
        An array of PlatyPS CommandHelp objects to list on the index page.

    .PARAMETER Theme
        A hashtable of CSS variable names to values, as returned by Resolve-HtmlTheme.
        When empty or omitted, the built-in default theme is used.

    .EXAMPLE
        ```powershell
        $commands = Measure-PlatyPSMarkdown -Path .\docs\MyModule\*.md |
            Where-Object Filetype -match 'CommandHelp' |
            Import-MarkdownCommandHelp -Path { $_.FilePath }
        $indexParams = @{
            ModuleName = 'MyModule'
            Commands   = $commands
            Theme      = Resolve-HtmlTheme
        }
        New-ModuleIndexPage @indexParams
        ```

        Returns the HTML string for the MyModule index page listing all commands.
    #>
    param(
        [string] $ModuleName,
        [Microsoft.PowerShell.PlatyPS.Model.CommandHelp[]] $Commands,
        [hashtable] $Theme = @{}
    )

    $moduleEncoded = ConvertTo-HtmlEncoded $ModuleName
    $dateStamp     = Get-Date -Format 'yyyy-MM-dd HH:mm'

    $sidebarLinks = foreach ($cmd in $Commands | Sort-Object Title) {
        $encodedName = ConvertTo-HtmlEncoded $cmd.Title
        "        <li><a href='$encodedName.html'>$encodedName</a></li>"
    }

    $rows = foreach ($cmd in $Commands | Sort-Object Title) {
        $name     = ConvertTo-HtmlEncoded $cmd.Title
        $synopsis = ConvertTo-HtmlEncoded $cmd.Synopsis
        @"
                <tr>
                    <td><a href="$name.html"><code>$name</code></a></td>
                    <td>$synopsis</td>
                </tr>
"@
    }

    # Build :root CSS-variable block from the resolved theme hashtable.
    # If $Theme is empty (direct call without Export-HtmlCommandHelp), fall back to defaults.
    $effectiveTheme = if ($Theme.Count -gt 0) { $Theme } else { Resolve-HtmlTheme }
    $cssVars = ($effectiveTheme.GetEnumerator() | ForEach-Object {
        "        --$($_.Key): $($_.Value);"
    }) -join "`n"

    @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$moduleEncoded - Module Help</title>
    <style>
        :root {
$cssVars
        }

        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        body   { font-family: var(--font-body);
                 font-size: 16px; line-height: 1.6; color: var(--color-body-fg);
                 background: var(--color-body-bg); }
        a      { color: var(--color-link); text-decoration: none; }
        a:hover { text-decoration: underline; }
        code   { font-family: var(--font-code);
                 background: var(--color-code-bg); padding: 0.1em 0.35em; border-radius: 3px;
                 font-size: 0.9em; }

        /* ---- Header ---- */
        .page-header { background: var(--color-header-bg); color: var(--color-header-fg);
                       padding: 1.25rem 2rem; }
        .page-header .label { font-size: 0.875rem; opacity: 0.75; }
        .page-header h1 { font-size: 1.75rem; font-weight: 600; margin: 0.25rem 0 0; }
        .page-header .meta { font-size: 0.8rem; opacity: 0.6; margin-top: 0.4rem; }

        /* ---- Two-column layout ---- */
        .layout  { display: flex; align-items: flex-start;
                   max-width: 1200px; margin: 0 auto; padding: 1.5rem; gap: 2rem; }

        /* ---- Sidebar ---- */
        .sidebar { width: 200px; flex-shrink: 0; position: sticky; top: 1rem; }
        .sidebar h2 { font-size: 0.7rem; font-weight: 700; text-transform: uppercase;
                      letter-spacing: 0.08em; color: var(--color-sidebar-label);
                      margin-bottom: 0.5rem; }
        .sidebar ul { list-style: none; padding: 0; margin: 0; }
        .sidebar li { margin: 0; }
        .sidebar li a { display: block; padding: 0.25rem 0.5rem; font-size: 0.85rem;
                        font-family: var(--font-code); color: var(--color-link);
                        border-radius: 3px; }
        .sidebar li a:hover { background: var(--color-sidebar-hover-bg); text-decoration: none; }

        /* ---- Main content ---- */
        main { flex: 1; min-width: 0; }

        h2 { font-size: 1.2rem; font-weight: 700; text-transform: uppercase;
             letter-spacing: 0.05em; border-bottom: 2px solid var(--color-accent);
             padding-bottom: 0.3rem; margin-bottom: 0.75rem; color: var(--color-accent-dark); }

        table  { border-collapse: collapse; width: 100%; margin-top: 0.5rem; background: var(--color-table-bg); }
        th, td { border: 1px solid var(--color-border); padding: 0.5rem 0.8rem; text-align: left; }
        th     { background: var(--color-th-bg); font-weight: 600; }
        tr:hover td { background: var(--color-tr-hover-bg); }

        footer { text-align: center; font-size: 0.8rem; color: var(--color-footer-fg);
                 border-top: 1px solid var(--color-border); padding: 1rem; margin-top: 3rem; }
    </style>
</head>
<body>
    <header class="page-header">
        <div class="label">Module Reference</div>
        <h1>$moduleEncoded</h1>
        <div class="meta">$($Commands.Count) command$(if ($Commands.Count -ne 1) { 's' })</div>
    </header>

    <div class="layout">
        <nav class="sidebar">
            <h2>Commands</h2>
            <ul>
$($sidebarLinks -join "`n")
            </ul>
        </nav>
        <main>
            <section>
                <h2>Commands</h2>
                <table>
                    <thead>
                        <tr><th>Name</th><th>Synopsis</th></tr>
                    </thead>
                    <tbody>
$($rows -join "`n")
                    </tbody>
                </table>
            </section>
        </main>
    </div>

    <footer>
        Generated by PlatyPS.Hosting &mdash; $dateStamp
    </footer>
</body>
</html>
"@
}

function Publish-ModuleHelp {
    <#
        .SYNOPSIS
        Publishes PowerShell module HTML help files to an IIS web server.

        .DESCRIPTION
        Publish-ModuleHelp stops the specified IIS website and copies the provided HTML
        help content to the site's root directory. Use this function after generating HTML
        help with Export-HtmlCommandHelp to deploy the output to a local or remote IIS site.

        .PARAMETER SiteName
        The name of the IIS site to publish help content to. The site will be stopped
        before the content is copied.

        .PARAMETER SiteRoot
        The file system path to the root folder of the IIS site where the help content
        will be copied.

        .PARAMETER HelpContent
        One or more paths to the HTML help files or folders to copy to the site root.

        .PARAMETER Computername
        The name of the remote computer hosting the IIS site. When specified, the
        operation is performed on the remote machine using Invoke-Command. If omitted,
        the operation runs locally.

        .PARAMETER Credential
        The credentials to use when connecting to the remote computer specified by
        Computername. If not provided, the current user's credentials are used.

        .PARAMETER Force
        When specified, overwrites existing files in the destination without prompting.

        .EXAMPLE
        ```powershell
        $publishParams = @{
            SiteName    = 'MyDocsSite'
            SiteRoot    = 'C:\moduledocs\mydocssite'
            HelpContent = '.\help\html\MyModule'
        }
        Publish-ModuleHelp @publishParams
        ```

        Stops the MyDocsSite IIS site and copies the HTML help files from the local
        .\help\html\MyModule folder to C:\moduledocs\mydocssite.

        .EXAMPLE
        ```powershell
        $publishParams = @{
            SiteName    = 'MyDocsSite'
            SiteRoot    = 'C:\moduledocs\mydocssite'
            HelpContent = '.\help\html\MyModule'
            Force       = $true
        }
        Publish-ModuleHelp @publishParams
        ```

        Stops the MyDocsSite IIS site and copies the HTML help files, overwriting any
        existing files in the destination.

        .EXAMPLE
        ```powershell
        $publishParams = @{
            SiteName     = 'MyDocsSite'
            SiteRoot     = 'C:\moduledocs\mydocssite'
            HelpContent  = '.\help\html\MyModule'
            Computername = 'webserver01'
            Credential   = (Get-Credential)
        }
        Publish-ModuleHelp @publishParams
        ```

        Stops the MyDocsSite IIS site on the remote computer webserver01 and copies the
        HTML help files, authenticating with the provided credentials.

        .NOTES
    #>
    [CmdletBinding(HelpUri='https://steviecoaster.github.io/PlatyPS.Hosting/PlatyPS.Hosting/Publish-ModuleHelp/')]
    Param(
        [Parameter()]
        [String]
        $SiteName,

        [Parameter()]
        [String]
        $SiteRoot,

        [Parameter()]
        [String[]]
        $HelpContent,

        [Parameter()]
        [String]
        $Computername,

        [Parameter()]
        [PSCredential]
        $Credential,

        [Parameter()]
        [Switch]
        $Force
    )

    if (-not $Computername) {
        Stop-Website -Name $SiteName

        Copy-Item $HelpContent -Destination $SiteRoot -Force:$($Force.IsPresent)

        Start-Website -Name $SiteName
    }
    else {
        $sessionParams = @{
            ComputerName = $Computername
        }
        if ($Credential) {
            $sessionParams['Credential'] = $Credential
        }

        $session = New-PSSession @sessionParams

        # Copy local files into the remote SiteRoot
        Copy-Item $HelpContent -Destination $SiteRoot -ToSession $session -Recurse -Force:$($Force.IsPresent)

        # Then stop/start the site remotely
        Invoke-Command -Session $session -ScriptBlock {
            Stop-Website -Name $using:SiteName
            # Files already copied, just restart the site
            Start-Website -Name $using:SiteName
        }

        Remove-PSSession $session
    }
    
}
function Resolve-HtmlTheme {
    <#
    .SYNOPSIS
        Loads a theme psd1 and merges it over the built-in defaults.

    .DESCRIPTION
        Returns a flat hashtable of CSS variable values keyed by variable name
        (without the leading --).  Any keys present in the caller-supplied file
        override the built-in defaults; missing keys fall back to the defaults.

    .PARAMETER ThemeFile
        Optional path to a .psd1 theme file.  When omitted the built-in default
        theme is returned.

    .EXAMPLE
        ```powershell
        Resolve-HtmlTheme
        ```

        Returns the built-in default theme hashtable with all CSS variable values.

    .EXAMPLE
        ```powershell
        $themeParams = @{
            ThemeFile = '.\themes\Dracula.psd1'
        }
        Resolve-HtmlTheme @themeParams
        ```

        Loads the Dracula theme file and merges it over the built-in defaults,
        returning the combined hashtable.
    #>
    param(
        [string] $ThemeFile
    )

    $defaults = [ordered]@{
        'color-header-bg'          = '#041e49'
        'color-header-fg'          = '#ffffff'
        'color-accent'             = '#0078d4'
        'color-accent-dark'        = '#041e49'
        'color-home-btn-border'    = '#3355aa'
        'color-home-btn-hover-bg'  = '#0a2d6e'
        'color-link'               = '#0078d4'
        'color-body-bg'            = '#f8f9fa'
        'color-body-fg'            = '#1a1a1a'
        'color-code-bg'            = '#e8eaed'
        'color-pre-bg'             = '#1e1e1e'
        'color-pre-fg'             = '#d4d4d4'
        'color-border'             = '#dde'
        'color-th-bg'              = '#f0f2f5'
        'color-tr-hover-bg'        = '#f5f8ff'
        'color-sidebar-label'      = '#666666'
        'color-sidebar-hover-bg'   = '#e8f0fb'
        'color-sidebar-current-bg' = '#dde8f8'
        'color-sidebar-current-fg' = '#041e49'
        'color-badge-required-bg'  = '#c50f1f'
        'color-badge-position-bg'  = '#0078d4'
        'color-badge-dontshow-bg'  = '#999999'
        'color-footer-fg'          = '#999999'
        'color-table-bg'           = '#ffffff'

        'font-body'  = "'Segoe UI', Tahoma, Geneva, Verdana, sans-serif"
        'font-code'  = "Consolas, 'Courier New', monospace"
    }

    if (-not $ThemeFile) {
        return $defaults
    }

    $resolved = $PSCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ThemeFile)

    if (-not (Test-Path $resolved)) {
        throw "Theme file not found: $resolved"
    }

    $userTheme = Import-PowerShellDataFile -LiteralPath $resolved

    $merged = [ordered]@{} + $defaults
    foreach ($key in $userTheme.Keys) {
        $merged[$key] = $userTheme[$key]
    }

    return $merged
}

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

