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
        ConvertTo-HugoFormat -Path .\help\markdown\PlatyPS.Hosting -OutputFolder .\hugo\content\PlatyPS.Hosting -RootIndex

        Converts all PlatyPS Markdown files and also generates .\hugo\content\_index.md
        from the module description and cmdlet synopses.

    .EXAMPLE
        Get-Item .\help\markdown\MyModule\New-Widget.md |
            ConvertTo-HugoFormat -OutputFolder .\hugo\content\MyModule -PassThru

        Converts a single file and returns the resulting FileInfo to the pipeline.
    #>
    [CmdletBinding(SupportsShouldProcess)]
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
