BeforeAll {
    $RepoRoot = Split-Path -Parent $PSScriptRoot
    $ModuleRoot = Join-Path $RepoRoot -ChildPath 'PlatyPS.Hosting'
    $ModuleManifest = Join-Path $ModuleRoot -ChildPath 'PlatyPS.Hosting.psd1'
    Import-Module $ModuleManifest -Force

    if (-not (Get-Module -Name 'Microsoft.PowerShell.PlatyPS')) {
        Import-Module Microsoft.PowerShell.PlatyPS -ErrorAction SilentlyContinue
    }

    $script:MarkdownRoot = Join-Path $RepoRoot 'help' 'markdown' 'PlatyPS.Hosting'
    $script:CommonParameters = [System.Management.Automation.PSCmdlet]::CommonParameters
}

$publicFunctions = (Get-Command -Module PlatyPS.Hosting).Name

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
        $command.Definition | Should -Not -BeNullOrEmpty
    }

    It 'CommandInfo has Parameters' {
        $command.Parameters | Should -Not -BeNullOrEmpty
        $command.Parameters.Count | Should -BeGreaterThan 0
    }
}

Describe '<Function> - Markdown Help' -ForEach ($publicFunctions | ForEach-Object { @{ Function = $_ } }) {
    BeforeAll {
        $markdownPath = Join-Path $script:MarkdownRoot "$Function.md"
        $script:cmdHelp = $null
        if ((Test-Path $markdownPath) -and
            (Get-Command -Name 'Import-MarkdownCommandHelp' -ErrorAction SilentlyContinue)) {
            $script:cmdHelp = Import-MarkdownCommandHelp -Path $markdownPath -ErrorAction SilentlyContinue
        }

        # Build parameter cross-reference table (pattern from Test-ParameterInfo.ps1)
        $script:paramResults = @{}
        if ($script:cmdHelp) {
            $cmdInfo = Get-Command -Name $Function
            $cmdParameters = $cmdInfo.Parameters.Keys | Where-Object { $_ -notin $script:CommonParameters }
            foreach ($cp in $cmdParameters) {
                $script:paramResults[$cp] = [pscustomobject]@{
                    Name         = $cp
                    IsDefined    = $true
                    IsDocumented = $false
                }
            }
            foreach ($mdp in $script:cmdHelp.Parameters.Name) {
                if ($mdp -in $script:paramResults.Keys) {
                    $script:paramResults[$mdp].IsDocumented = $true
                } else {
                    $script:paramResults[$mdp] = [pscustomobject]@{
                        Name         = $mdp
                        IsDefined    = $false
                        IsDocumented = $true
                    }
                }
            }
        }
    }

    It 'has a Markdown source file' {
        Join-Path $script:MarkdownRoot "$Function.md" | Should -Exist
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

    It 'every command parameter is documented in Markdown' {
        if (-not $script:cmdHelp) { Set-ItResult -Skipped -Because 'CommandHelp object could not be loaded' }
        $undocumented = $script:paramResults.Values | Where-Object { $_.IsDefined -and -not $_.IsDocumented }
        $undocumented | Should -BeNullOrEmpty -Because (
            "These parameters are defined but not documented: $($undocumented.Name -join ', ')"
        )
    }

    It 'every documented parameter is defined in the command' {
        if (-not $script:cmdHelp) { Set-ItResult -Skipped -Because 'CommandHelp object could not be loaded' }
        $extra = $script:paramResults.Values | Where-Object { -not $_.IsDefined -and $_.IsDocumented }
        $extra | Should -BeNullOrEmpty -Because (
            "These parameters are documented but not defined: $($extra.Name -join ', ')"
        )
    }

    It 'every documented parameter has a description' {
        if (-not $script:cmdHelp) { Set-ItResult -Skipped -Because 'CommandHelp object could not be loaded' }
        $script:cmdHelp.Parameters | ForEach-Object {
            $_.Description | Should -Not -BeNullOrEmpty -Because "-$($_.Name) needs a description"
        }
    }

    It 'no parameter description contains unfilled PlatyPS placeholders' {
        if (-not $script:cmdHelp) { Set-ItResult -Skipped -Because 'CommandHelp object could not be loaded' }
        $script:cmdHelp.Parameters | ForEach-Object {
            $_.Description | Should -Not -Match '\{\{.+\}\}' `
                -Because "-$($_.Name) parameter description must not be a placeholder"
        }
    }
}

Describe 'PlatyPS.Hosting - Module Markdown File' {
    BeforeAll {
        $script:moduleMdPath = Join-Path $script:MarkdownRoot 'PlatyPS.Hosting.md'
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

    It '<Function> is listed in the module Markdown file' `
        -ForEach ($publicFunctions | ForEach-Object { @{ Function = $_ } }) {
        $script:moduleMdPath | Should -FileContentMatch ([regex]::Escape($Function))
    }
}

Describe '<Function> - Related Links' -ForEach ($publicFunctions | ForEach-Object { @{ Function = $_ } }) {
    BeforeAll {
        $markdownPath = Join-Path $script:MarkdownRoot "$Function.md"
        $script:uris = @()
        if ((Test-Path $markdownPath) -and
            (Get-Command -Name 'Import-MarkdownCommandHelp' -ErrorAction SilentlyContinue)) {
            $cmdHelp = Import-MarkdownCommandHelp -Path $markdownPath -ErrorAction SilentlyContinue
            if ($cmdHelp) {
                $script:uris = @(
                    $cmdHelp.RelatedLinks |
                        Where-Object { -not [string]::IsNullOrWhiteSpace($_.Uri) -and $_.Uri -match '^https?://' } |
                        Select-Object -ExpandProperty Uri
                )
            }
        }
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