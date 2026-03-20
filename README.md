# PlatyPS.Hosting

PlatyPS.Hosting is a PowerShell module that extends the [Microsoft.PowerShell.PlatyPS](https://github.com/PowerShell/platyPS) v1 help authoring workflow. It provides three commands that together let you go from a loaded module to a published, browser-friendly HTML documentation site hosted on IIS.

```
New-ModuleHelp          # reflection → MAML + Markdown (+ optional HTML)
Export-HtmlCommandHelp  # CommandHelp objects → static HTML site
Publish-ModuleHelp      # HTML files → IIS web server (local or remote)
```

---

## Requirements

| Requirement | Notes |
|-------------|-------|
| PowerShell 5.1 or 7+ | |
| [Microsoft.PowerShell.PlatyPS](https://github.com/PowerShell/platyPS) | `Install-Module Microsoft.PowerShell.PlatyPS` |
| WebAdministration module | Needed for `Stop-Website` / `Start-Website` on the IIS host |
| IIS installed on the target server | Local or remote |
| Appropriate permissions | Stop/start IIS sites; write to the site root |

---

## Installation

```powershell
Import-Module .\PlatyPS.Hosting.psd1
```

---

## Commands

### `New-ModuleHelp`

Generates all help artifacts for a loaded module in a single pass.

Performs one reflection pass against the live module and writes up to three outputs into sub-folders under `OutputFolder`:

| Output | Path | Tool used |
|--------|------|-----------|
| MAML XML | `<OutputFolder>\maml\<ModuleName>\` | `Export-MamlCommandHelp` |
| Markdown | `<OutputFolder>\markdown\<ModuleName>\` | `New-MarkdownCommandHelp` |
| HTML site *(optional)* | `<OutputFolder>\html\<ModuleName>\` | `Export-HtmlCommandHelp` |

> **Note:** HTML is generated from the Markdown files rather than from live reflection, so any hand-edited descriptions, examples, and notes are included. On subsequent runs, use `Update-MarkdownCommandHelp` to preserve hand-written Markdown content before regenerating HTML.

#### Syntax

```powershell
New-ModuleHelp
    -ModuleName <String>
    -OutputFolder <String>
    [-Html]
    [-ThemeFile <String>]
```

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `ModuleName` | `String` | Yes | Name of the module to generate help for. The module must already be loaded in the current session. |
| `OutputFolder` | `String` | Yes | Root folder for the generated artifacts. Created automatically if it does not exist. |
| `Html` | `Switch` | No | Also produce a static HTML site under `<OutputFolder>\html\`. |
| `ThemeFile` | `String` | No | Path to a `.psd1` theme file passed through to `Export-HtmlCommandHelp`. See [Themes](#themes). |

#### Examples

```powershell
# MAML + Markdown only
Import-Module MyModule
New-ModuleHelp -ModuleName MyModule -OutputFolder .\docs

# MAML + Markdown + HTML with the Dracula theme
Import-Module MyModule
New-ModuleHelp -ModuleName MyModule -OutputFolder .\docs -Html -ThemeFile .\themes\Dracula.psd1
```

---

### `Export-HtmlCommandHelp`

Converts PlatyPS `CommandHelp` objects into a self-contained static HTML documentation site.

Accepts `CommandHelp` objects on the pipeline (from `New-CommandHelp` or `Import-MarkdownCommandHelp`) and writes one HTML page per command plus an `index.html` module landing page. All pages share a sidebar for navigation.

#### Syntax

```powershell
Export-HtmlCommandHelp
    -CommandHelp <CommandHelp[]>
    [-OutputFolder] <String>
    [-ThemeFile <String>]
    [-Force]
    [-PassThru]
```

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `CommandHelp` | `CommandHelp[]` | Yes | One or more PlatyPS `CommandHelp` objects. Accepts pipeline input. |
| `OutputFolder` | `String` | Yes | Root folder for the HTML files. A sub-folder named after the module is created automatically. |
| `ThemeFile` | `String` | No | Path to a `.psd1` theme file. Keys present in the file override the built-in defaults; missing keys keep their default values. See [Themes](#themes). |
| `Force` | `Switch` | No | Overwrite existing HTML files without prompting. |
| `PassThru` | `Switch` | No | Emit the generated `FileInfo` objects to the pipeline. |

#### Examples

```powershell
# From live reflection
Get-Command -Module MyModule |
    New-CommandHelp |
    Export-HtmlCommandHelp -OutputFolder .\help\html -Force

# From existing Markdown files
Measure-PlatyPSMarkdown -Path .\docs\MyModule\*.md |
    Where-Object Filetype -match 'CommandHelp' |
    Import-MarkdownCommandHelp -Path { $_.FilePath } |
    Export-HtmlCommandHelp -OutputFolder .\help\html -ThemeFile .\themes\Synthwave.psd1 -Force
```

---

### `Publish-ModuleHelp`

Publishes generated HTML help files to an IIS web server.

Stops the specified IIS site, copies the HTML content to the site root, and restarts the site. Supports both local deployments and remote deployments over PowerShell remoting.

#### Syntax

```powershell
Publish-ModuleHelp
    [-SiteName <String>]
    [-SiteRoot <String>]
    [-HelpContent <String[]>]
    [-Computername <String>]
    [-Credential <PSCredential>]
    [-Force]
```

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `SiteName` | `String` | The name of the IIS site to publish to. Stopped before the copy and restarted afterward. |
| `SiteRoot` | `String` | File system path to the IIS site root on the target machine where files will be copied. |
| `HelpContent` | `String[]` | One or more local paths to HTML files or folders to deploy. |
| `Computername` | `String` | Remote host running IIS. When provided, files are transferred via a PSSession and IIS commands run remotely. Omit for a local deployment. |
| `Credential` | `PSCredential` | Credentials for the remote connection. Uses the current user if omitted. |
| `Force` | `Switch` | Overwrite existing files in the destination without prompting. |

#### Examples

```powershell
# Local deployment
Publish-ModuleHelp -SiteName MyDocsSite `
                   -SiteRoot C:\inetpub\mydocssite `
                   -HelpContent .\help\html\MyModule `
                   -Force

# Remote deployment
$cred = Get-Credential
Publish-ModuleHelp -SiteName MyDocsSite `
                   -SiteRoot C:\inetpub\mydocssite `
                   -HelpContent (Get-ChildItem .\help\html -Filter *.html -Recurse).FullName `
                   -Computername webserver01 `
                   -Credential $cred `
                   -Force
```

---

## Themes

Three built-in themes ship with the module under the `themes\` folder. Pass the path to any of them via `-ThemeFile` on `Export-HtmlCommandHelp` or `New-ModuleHelp`.

| File | Description |
|------|-------------|
| `themes\Default.psd1` | Clean light theme with a navy/blue accent (Microsoft-inspired) |
| `themes\Dracula.psd1` | Dark theme using the Dracula color palette |
| `themes\Synthwave.psd1` | Dark theme with neon/retro Synthwave colors |

To create a custom theme, copy `Default.psd1` and override only the keys you want to change. Any key not present in your file falls back to the built-in default automatically.

```powershell
# Apply the Dracula theme
New-ModuleHelp -ModuleName MyModule -OutputFolder .\docs -Html -ThemeFile .\themes\Dracula.psd1
```

---

## End-to-End Workflow

```powershell
# 1. Import the modules
Import-Module Microsoft.PowerShell.PlatyPS
Import-Module .\PlatyPS.Hosting.psd1
Import-Module MyModule

# 2. Generate MAML, Markdown, and HTML in one step
New-ModuleHelp -ModuleName MyModule `
               -OutputFolder .\help `
               -Html `
               -ThemeFile .\themes\Dracula.psd1

# 3. Publish to a local IIS site
Publish-ModuleHelp -SiteName MyDocsSite `
                   -SiteRoot C:\inetpub\mydocssite `
                   -HelpContent .\help\html\MyModule `
                   -Force

# 3. (or) Publish to a remote IIS server
Publish-ModuleHelp -SiteName MyDocsSite `
                   -SiteRoot C:\inetpub\mydocssite `
                   -HelpContent (Get-ChildItem .\help\html\MyModule -Filter *.html -Recurse).FullName `
                   -Computername webserver01 `
                   -Credential (Get-Credential) `
                   -Force
```

---

## Related Links

- [Microsoft.PowerShell.PlatyPS on GitHub](https://github.com/PowerShell/platyPS)
- [IIS WebAdministration module](https://learn.microsoft.com/en-us/powershell/module/webadministration/)
