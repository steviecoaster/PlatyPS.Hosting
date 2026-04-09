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
