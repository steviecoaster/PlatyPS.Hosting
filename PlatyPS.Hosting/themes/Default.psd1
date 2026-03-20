# PlatyPS.Hosting – Default theme
# Copy this file, change any values, and pass the path to -ThemeFile on
# Export-HtmlCommandHelp or New-ModuleHelp.
#
# Only include the keys you want to override – missing keys fall back to
# these built-in defaults automatically.
@{
    # ── Colours ──────────────────────────────────────────────────────────────

    # Dark header bar background / page accent-dark
    'color-header-bg'          = '#041e49'
    # Header text colour
    'color-header-fg'          = '#ffffff'
    # Primary accent (links, section underlines, badges)
    'color-accent'             = '#0078d4'
    # Secondary dark accent (section headings, sidebar current-item text)
    'color-accent-dark'        = '#041e49'

    # Home button border in the header
    'color-home-btn-border'    = '#3355aa'
    # Home button hover background
    'color-home-btn-hover-bg'  = '#0a2d6e'

    # Hyperlink colour
    'color-link'               = '#0078d4'

    # Page background / body text
    'color-body-bg'            = '#f8f9fa'
    'color-body-fg'            = '#1a1a1a'

    # Inline <code> chip background
    'color-code-bg'            = '#e8eaed'
    # <pre> block colours
    'color-pre-bg'             = '#1e1e1e'
    'color-pre-fg'             = '#d4d4d4'

    # Table / card borders
    'color-border'             = '#dde'
    # Table header cell background
    'color-th-bg'              = '#f0f2f5'
    # Table row hover background
    'color-tr-hover-bg'        = '#f5f8ff'

    # Sidebar section-label colour
    'color-sidebar-label'      = '#666666'
    # Sidebar link hover background
    'color-sidebar-hover-bg'   = '#e8f0fb'
    # Currently-active sidebar item
    'color-sidebar-current-bg' = '#dde8f8'
    'color-sidebar-current-fg' = '#041e49'

    # Parameter badge backgrounds (text is always #fff)
    'color-badge-required-bg'  = '#c50f1f'
    'color-badge-position-bg'  = '#0078d4'
    'color-badge-dontshow-bg'  = '#999999'

    # Footer text colour
    'color-footer-fg'          = '#999999'
    # Command table background
    'color-table-bg'           = '#ffffff'

    # ── Typography ───────────────────────────────────────────────────────────
    'font-body' = "'Segoe UI', Tahoma, Geneva, Verdana, sans-serif"
    'font-code' = "Consolas, 'Courier New', monospace"
}
