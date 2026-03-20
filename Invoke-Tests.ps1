<#
.SYNOPSIS
    Pester v5 test harness for PlatyPS.Hosting.

.DESCRIPTION
    Configures and runs the Pester v5 test suite for PlatyPS.Hosting.
    Imports the module from the same directory before running so tests
    always exercise the local source, not a previously installed version.

.PARAMETER Output
    Pester output verbosity.  Defaults to 'Detailed'.
    Valid values: None, Normal, Detailed, Diagnostic.

.PARAMETER TestPath
    Folder (or file) containing tests.  Defaults to .\tests.

.PARAMETER PassThru
    Return the Pester result object to the caller instead of only
    printing it.  Useful for CI pipelines that need to inspect results.

.PARAMETER CI
    Enables CI mode: sets output to Normal, enables exit code on failure,
    and produces a NUnit XML results file at .\TestResults.xml.

.EXAMPLE
    .\Invoke-Tests.ps1

    Runs all tests with Detailed output.

.EXAMPLE
    .\Invoke-Tests.ps1 -CI

    Runs all tests in CI mode and writes TestResults.xml.

.EXAMPLE
    .\Invoke-Tests.ps1 -TestPath .\tests\CommandInfo.tests.ps1 -Output Diagnostic

    Runs a single test file with maximum verbosity.
#>
[CmdletBinding()]
param(
    [ValidateSet('None', 'Normal', 'Detailed', 'Diagnostic')]
    [string] $Output = 'Detailed',

    [string] $TestPath = (Join-Path $PSScriptRoot 'tests'),

    [switch] $PassThru,

    [switch] $CI
)

$config = New-PesterConfiguration

$config.Run.Path      = $TestPath
$config.Run.PassThru  = $true

$config.Output.Verbosity = if ($CI) { 'Normal' } else { $Output }

$config.TestResult.Enabled      = $CI.IsPresent
$config.TestResult.OutputPath   = Join-Path $PSScriptRoot 'TestResults.xml'
$config.TestResult.OutputFormat = 'NUnitXml'

$config.CodeCoverage.Enabled = $false

$result = Invoke-Pester -Configuration $config

if ($CI -and $result.FailedCount -gt 0) {
    Write-Error "$($result.FailedCount) test(s) failed."
    exit 1
}

if ($PassThru) {
    $result
}
