BeforeAll {
    $RepoRoot = Split-Path -Parent $PSScriptRoot
    $ModuleRoot = Join-Path $RepoRoot -ChildPath 'PlatyPS.Hosting'
    $ModuleManifest = Join-Path $ModuleRoot -ChildPath 'PlatyPS.Hosting.psd1'
    Import-Module $ModuleManifest -Force

    if (-not (Get-Command -Name 'Import-MarkdownCommandHelp' -ErrorAction SilentlyContinue)) {
        Import-Module Microsoft.PowerShell.PlatyPS -ErrorAction SilentlyContinue
    }
}

$publicFunctions =(Get-Command -Module PlatyPS.Hosting).Name

Describe '<Function> - Module Export' -ForEach ($publicFunctions | ForEach-Object { @{ Function = $_ } }) {
    It 'is exported by PlatyPS.Hosting' {
        Get-Command -Module PlatyPS.Hosting -Name $Function | Should -Not -BeNullOrEmpty
    }
}

Describe '<Function> - CommandInfo' -ForEach ($publicFunctions | ForEach-Object { @{ Function = $_ } }) {
    BeforeAll {
        $command = Get-Command -Name $Function -ErrorAction SilentlyContinue
    }

    It 'has a CommandInfo object' {
        $command | Should -Not -BeNullOrEmpty
    }

    It 'CommandInfo has a Definition (Syntax)' {
        # Definition exposes the full source / param block – always non-empty for functions
        $command.Definition | Should -Not -BeNullOrEmpty
    }

    It 'CommandInfo has Parameters' {
        $command.Parameters | Should -Not -BeNullOrEmpty
        $command.Parameters.Count | Should -BeGreaterThan 0
    }
}

Describe '<Function> - Help Content' -ForEach ($publicFunctions | ForEach-Object { @{ Function = $_ } }) {
    BeforeAll {
        $help = Get-Help -Name $Function -Full
    }

    It 'has Syntax' {
        $help.syntax | Should -Not -BeNullOrEmpty
    }

    It 'has a Description' {
        $help.description | Should -Not -BeNullOrEmpty
        ($help.description | Select-Object -ExpandProperty Text -ErrorAction SilentlyContinue) |
            Should -Not -BeNullOrEmpty
    }

    It 'Description does not contain unfilled PlatyPS placeholders' {
        $text = ($help.description | Select-Object -ExpandProperty Text -ErrorAction SilentlyContinue) -join ' '
        $text | Should -Not -Match '\{\{.+\}\}' -Because 'placeholder text must be replaced with real content'
    }

    It 'has at least one Example' {
        $help.examples.example | Should -Not -BeNullOrEmpty
        @($help.examples.example).Count | Should -BeGreaterOrEqual 1
    }

    It 'no Example contains unfilled PlatyPS placeholders' {
        $help.examples.example | ForEach-Object {
            $exampleText = "$($_.introduction)$($_.code)$($_.remarks)"
            $exampleText | Should -Not -Match '\{\{.+\}\}' `
                -Because "Example '$($_.title)' must have real content, not placeholder text"
        }
    }

    It 'has Parameters documented' {
        $help.parameters.parameter | Should -Not -BeNullOrEmpty
    }

    It 'every documented parameter has a description' {
        $help.parameters.parameter | ForEach-Object {
            $_.description.Text |
                Should -Not -BeNullOrEmpty -Because "-$($_.name) needs a description"
        }
    }

    It 'no parameter description contains unfilled PlatyPS placeholders' {
        $help.parameters.parameter | ForEach-Object {
            $desc = $_.description.Text -join ' '
            $desc | Should -Not -Match '\{\{.+\}\}' `
                -Because "-$($_.name) parameter description must not contain placeholder text"
        }
    }
}

Describe '<Function> - Markdown File Structure' -ForEach ($publicFunctions | ForEach-Object { @{ Function = $_ } }) {
    BeforeAll {
        $markdownPath = "$PSScriptRoot\..\PlatyPS.Hosting\help\markdown\PlatyPS.Hosting\$Function.md"
        $script:cmdHelp = $null
        if ((Test-Path $markdownPath) -and
            (Get-Command -Name 'Import-MarkdownCommandHelp' -ErrorAction SilentlyContinue)) {
            $script:cmdHelp = Import-MarkdownCommandHelp -Path $markdownPath -ErrorAction SilentlyContinue
        }
    }

    It 'has a Markdown source file' {
        $markdownPath | Should -Exist
    }

    It 'can be imported as a CommandHelp object' {
        if (-not (Get-Command -Name 'Import-MarkdownCommandHelp' -ErrorAction SilentlyContinue)) {
            Set-ItResult -Skipped -Because 'Microsoft.PowerShell.PlatyPS is not available'
        }
        $script:cmdHelp | Should -Not -BeNullOrEmpty
    }

    It 'has no Diagnostic errors' {
        if (-not $script:cmdHelp) { Set-ItResult -Skipped -Because 'CommandHelp object could not be loaded' }
        $errors = $script:cmdHelp.Diagnostics.Messages | Where-Object Severity -eq 'Error'
        $errors | Should -BeNullOrEmpty -Because (
            "Markdown structural errors must be corrected: $($errors.Message -join '; ')"
        )
    }

    It 'has no Diagnostic warnings' {
        if (-not $script:cmdHelp) { Set-ItResult -Skipped -Because 'CommandHelp object could not be loaded' }
        $warnings = $script:cmdHelp.Diagnostics.Messages | Where-Object Severity -eq 'Warning'
        $warnings | Should -BeNullOrEmpty -Because (
            "Markdown structural warnings should be resolved: $($warnings.Message -join '; ')"
        )
    }

    It 'Synopsis is present and not a placeholder' {
        if (-not $script:cmdHelp) { Set-ItResult -Skipped -Because 'CommandHelp object could not be loaded' }
        $script:cmdHelp.Synopsis | Should -Not -BeNullOrEmpty
        $script:cmdHelp.Synopsis | Should -Not -Match '\{\{.+\}\}' `
            -Because 'Synopsis must be written, not left as a PlatyPS placeholder'
    }

    It 'Description is present and not a placeholder' {
        if (-not $script:cmdHelp) { Set-ItResult -Skipped -Because 'CommandHelp object could not be loaded' }
        $script:cmdHelp.Description | Should -Not -BeNullOrEmpty
        $script:cmdHelp.Description | Should -Not -Match '\{\{.+\}\}' `
            -Because 'Description must be written, not left as a PlatyPS placeholder'
    }

    It 'has at least one Syntax entry' {
        if (-not $script:cmdHelp) { Set-ItResult -Skipped -Because 'CommandHelp object could not be loaded' }
        @($script:cmdHelp.Syntax).Count | Should -BeGreaterOrEqual 1
    }

    It 'has at least one Example' {
        if (-not $script:cmdHelp) { Set-ItResult -Skipped -Because 'CommandHelp object could not be loaded' }
        @($script:cmdHelp.Examples).Count | Should -BeGreaterOrEqual 1
    }

    It 'no Example contains unfilled PlatyPS placeholders' {
        if (-not $script:cmdHelp) { Set-ItResult -Skipped -Because 'CommandHelp object could not be loaded' }
        $script:cmdHelp.Examples | ForEach-Object {
            "$($_.Title)$($_.Introduction)$($_.Code)$($_.Remarks)" |
                Should -Not -Match '\{\{.+\}\}' `
                -Because "Example '$($_.Title)' must contain real content"
        }
    }

    It 'has Parameters documented' {
        if (-not $script:cmdHelp) { Set-ItResult -Skipped -Because 'CommandHelp object could not be loaded' }
        @($script:cmdHelp.Parameters).Count | Should -BeGreaterThan 0
    }

    It 'no Parameter description is a placeholder' {
        if (-not $script:cmdHelp) { Set-ItResult -Skipped -Because 'CommandHelp object could not be loaded' }
        $script:cmdHelp.Parameters | ForEach-Object {
            $_.Description | Should -Not -Match '\{\{.+\}\}' `
                -Because "-$($_.Name) parameter description must not be a placeholder"
        }
    }
}

# ─── 5. Module Markdown File (Import-MarkdownModuleFile) ─────────────────────

Describe 'PlatyPS.Hosting - Module Markdown File' {
    BeforeAll {
        $script:moduleMdPath = "$PSScriptRoot\..\PlatyPS.Hosting\help\markdown\PlatyPS.Hosting\PlatyPS.Hosting.md"
        $script:modHelp = $null
        if ((Test-Path $script:moduleMdPath) -and
            (Get-Command -Name 'Import-MarkdownModuleFile' -ErrorAction SilentlyContinue)) {
            $script:modHelp = Import-MarkdownModuleFile -Path $script:moduleMdPath -ErrorAction SilentlyContinue
        }
    }

    It 'has a module Markdown file' {
        $script:moduleMdPath | Should -Exist
    }

    It 'can be imported as a module help object' {
        if (-not (Get-Command -Name 'Import-MarkdownModuleFile' -ErrorAction SilentlyContinue)) {
            Set-ItResult -Skipped -Because 'Microsoft.PowerShell.PlatyPS is not available'
        }
        $script:modHelp | Should -Not -BeNullOrEmpty
    }

    It 'has no Diagnostic errors' {
        if (-not $script:modHelp) { Set-ItResult -Skipped -Because 'Module help object could not be loaded' }
        $errors = $script:modHelp.Diagnostics.Messages | Where-Object Severity -eq 'Error'
        $errors | Should -BeNullOrEmpty -Because (
            "Module markdown errors must be corrected: $($errors.Message -join '; ')"
        )
    }

    It 'has no Diagnostic warnings' {
        if (-not $script:modHelp) { Set-ItResult -Skipped -Because 'Module help object could not be loaded' }
        $warnings = $script:modHelp.Diagnostics.Messages | Where-Object Severity -eq 'Warning'
        $warnings | Should -BeNullOrEmpty -Because (
            "Module markdown warnings should be resolved: $($warnings.Message -join '; ')"
        )
    }

    # Verify every public function is referenced in the module index page
    It '<Function> is listed in the module Markdown file' `
        -ForEach ($publicFunctions | ForEach-Object { @{ Function = $_ } }) {
        $script:moduleMdPath | Should -FileContentMatch ([regex]::Escape($Function))
    }
}

Describe '<Function> - RelatedLinks' -ForEach ($publicFunctions | ForEach-Object { @{ Function = $_ } }) {
    BeforeAll {
        $help = Get-Help -Name $Function -Full
        $script:uris = @(
            $help.relatedLinks.navigationLink |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_.uri) -and $_.uri -match '^https?://' } |
                Select-Object -ExpandProperty uri
        )
    }

    It 'all related links resolve with HTTP 200' {
        if ($script:uris.Count -eq 0) {
            Set-ItResult -Skipped -Because 'no HTTP(S) related links are defined for this command'
        }
        foreach ($uri in $script:uris) {
            $response = Invoke-WebRequest -Uri $uri -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
            $response.StatusCode | Should -Be 200 -Because "$uri should return HTTP 200"
        }
    }
}