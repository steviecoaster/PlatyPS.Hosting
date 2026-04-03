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
    Get-Command -Module Microsoft.PowerShell.Utility |
        Select-Object -First 5 |
        New-CommandHelp |
        .\Export-HtmlCommandHelp.ps1 -OutputFolder .\html -Force

.EXAMPLE
    Import-MarkdownCommandHelp -Path .\docs\MyModule\Get-Widget.md |
        .\Export-HtmlCommandHelp.ps1 -OutputFolder .\html -PassThru

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