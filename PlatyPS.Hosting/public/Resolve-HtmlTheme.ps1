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
