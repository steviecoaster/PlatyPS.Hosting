function ConvertTo-Parameters {
    <#
    .SYNOPSIS
        Renders the parameters for a command as a detailed HTML section.

    .DESCRIPTION
        Accepts a PlatyPS CommandHelp model object and returns an HTML PARAMETERS
        <section> containing a subsection for each parameter with required/position
        badges, type, default value, aliases, accepted values, and wildcard support.
        Returns an empty string if the command has no parameters.

    .PARAMETER Help
        The PlatyPS CommandHelp model object to extract parameter information from.

    .EXAMPLE
        ```powershell
        $importParams = @{
            Path = '.\docs\MyModule\Get-Widget.md'
        }
        $help = Import-MarkdownCommandHelp @importParams
        ConvertTo-Parameters -Help $help
        ```

        Returns an HTML parameters section for the Get-Widget command.
    #>
    param([Microsoft.PowerShell.PlatyPS.Model.CommandHelp]$Help)
    if (-not $Help.Parameters -or $Help.Parameters.Count -eq 0) { return '' }

    $paramBlocks = foreach ($p in $Help.Parameters) {
        # ---- required / position badge ----
        $badges = @()
        # Check all parameter sets for Required/Position info
        foreach ($ps in $p.ParameterSets) {
            if ($ps.IsRequired) { $badges += '<span class="badge required">Required</span>' }
            if ($ps.Position -ge 0) { $badges += "<span class='badge position'>Position: $($ps.Position)</span>" }
        }
        if ($p.DontShow) { $badges += '<span class="badge dontshow">Don''t Show</span>' }
        $badgeHtml = if ($badges) { "<div class='badges'>$($badges -join ' ')</div>" } else { '' }

        # ---- meta table ----
        $metaRows = @(
            "<tr><th>Type</th><td><code>$(ConvertTo-HtmlEncoded $p.Type)</code></td></tr>"
            "<tr><th>Default Value</th><td>$(ConvertTo-HtmlEncoded $p.DefaultValue)</td></tr>"
        )
        if ($p.Aliases -and $p.Aliases.Count -gt 0) {
            $aliasText = ($p.Aliases | ForEach-Object { "<code>$_</code>" }) -join ', '
            $metaRows += "<tr><th>Aliases</th><td>$aliasText</td></tr>"
        }
        if ($p.AcceptedValues -and $p.AcceptedValues.Count -gt 0) {
            $vals = ($p.AcceptedValues | ForEach-Object { "<code>$(ConvertTo-HtmlEncoded $_)</code>" }) -join ', '
            $metaRows += "<tr><th>Accepted Values</th><td>$vals</td></tr>"
        }
        if ($p.SupportsWildcards) { $metaRows += '<tr><th>Wildcards</th><td>Yes</td></tr>' }

        @"
            <section class="parameter" id="param-$($p.Name.ToLower())">
                <h3>-$($p.Name)</h3>
                $badgeHtml
                <p>$(ConvertTo-HtmlEncoded $p.Description)</p>
                <table class="param-meta">$($metaRows -join '')</table>
            </section>
"@
    }
    Write-Section -Title 'PARAMETERS' -Content ($paramBlocks -join "`n")
}
