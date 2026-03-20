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
        Import-Module MyModule
        New-ModuleHelp -ModuleName MyModule -OutputFolder .\docs

        Generates MAML and Markdown help for MyModule under .\docs\.

    .EXAMPLE
        Import-Module PowerShellUniversal.Plaster
        New-ModuleHelp -ModuleName PowerShellUniversal.Plaster -OutputFolder .\docs -Html

        Generates MAML, Markdown, and HTML help for the module.
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
        $commandHelp = New-CommandHelp -CommandInfo (Get-Command -Module $ModuleName)

        $exportMamlCommandHelpSplat = @{
            CommandHelp = $commandHelp
            OutputFolder = (Join-Path $OutputFolder 'maml')
        }

        # Create Maml from CommandInfo objects
        Export-MamlCommandHelp @exportMamlCommandHelpSplat

        $newMarkdownCommandHelpSplat = @{
            ModuleInfo     = Get-Module -Name $ModuleName
            OutputFolder   = (Join-Path $OutputFolder 'markdown')
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