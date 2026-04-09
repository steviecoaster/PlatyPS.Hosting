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
