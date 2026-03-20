# Theme Engine

PlatyPS.Hosting uses a lightweight theme engine to control the appearance of generated HTML help pages. Themes are PowerShell data files (`.psd1`) containing key/value pairs that map directly to CSS custom properties (CSS variables) injected into every generated page.

---

## How it works

1. **Theme file is loaded** — `Resolve-HtmlTheme` reads the `.psd1` file you provide via `-ThemeFile` using `Import-PowerShellDataFile`.
2. **Merged over defaults** — The loaded keys are merged on top of the built-in defaults. Keys present in your file override the defaults; any key you omit keeps its default value.
3. **Injected as CSS variables** — The merged hashtable is written into a `:root { }` block at the top of each generated HTML page's `<style>` tag, with `--` prepended to each key name:

   ```css
   :root {
       --color-header-bg: #282a36;
       --color-accent: #bd93f9;
       --font-body: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
       /* ... */
   }
   ```

4. **Referenced throughout the CSS** — Every color and font used in the page layout reads from these variables via `var(--key-name)`.

Because only CSS variables are changed, the HTML structure and layout are identical across all themes — only colors and fonts differ.

---

## Using a theme

Pass any `.psd1` theme file to `-ThemeFile` on either `Export-HtmlCommandHelp` or `New-ModuleHelp`:

```powershell
# With Export-HtmlCommandHelp
Import-MarkdownCommandHelp -Path .\docs\MyModule\*.md |
    Export-HtmlCommandHelp -OutputFolder .\help\html -ThemeFile .\themes\Dracula.psd1

# With New-ModuleHelp
New-ModuleHelp -ModuleName MyModule -OutputFolder .\help -Html -ThemeFile .\themes\Synthwave.psd1
```

When `-ThemeFile` is omitted, the built-in Default theme is used automatically.

---

## Built-in themes

| File | Style | Accent colors |
|------|-------|----------------|
| `themes\Default.psd1` | Light, clean | Navy header, Microsoft blue (`#0078d4`) |
| `themes\Dracula.psd1` | Dark | Purple (`#bd93f9`), pink (`#ff79c6`), cyan links |
| `themes\Synthwave.psd1` | Dark, retro 80s | Hot pink (`#ff2d78`), neon purple, electric teal links |

---

## Creating a custom theme

Copy any of the existing theme files as a starting point and change only the values you want. Every key is optional — any key you leave out falls back to the built-in default.

```powershell
Copy-Item .\themes\Default.psd1 .\themes\MyTheme.psd1
```

Then edit `MyTheme.psd1`. For example, a minimal theme that only changes the accent colors:

```powershell
@{
    'color-header-bg'  = '#1a1a2e'
    'color-accent'     = '#e94560'
    'color-accent-dark'= '#16213e'
    'color-link'       = '#e94560'
}
```

---

## Theme keys reference

All keys are strings. Color values accept any valid CSS color (`#rrggbb`, `#rgb`, `rgb()`, named colors, etc.). Font values accept any valid CSS `font-family` string.

### Colors

#### Header

| Key | Default | Description |
|-----|---------|-------------|
| `color-header-bg` | `#041e49` | Header bar background |
| `color-header-fg` | `#ffffff` | Header bar text |
| `color-home-btn-border` | `#3355aa` | Home button border color |
| `color-home-btn-hover-bg` | `#0a2d6e` | Home button hover background |

#### Accents & links

| Key | Default | Description |
|-----|---------|-------------|
| `color-accent` | `#0078d4` | Primary accent — links, section underlines, badges |
| `color-accent-dark` | `#041e49` | Secondary accent — section headings, sidebar active text |
| `color-link` | `#0078d4` | Hyperlink color |

#### Body

| Key | Default | Description |
|-----|---------|-------------|
| `color-body-bg` | `#f8f9fa` | Page background |
| `color-body-fg` | `#1a1a1a` | Body text |

#### Code blocks

| Key | Default | Description |
|-----|---------|-------------|
| `color-code-bg` | `#e8eaed` | Inline `<code>` chip background |
| `color-pre-bg` | `#1e1e1e` | `<pre>` block background |
| `color-pre-fg` | `#d4d4d4` | `<pre>` block text |

#### Tables

| Key | Default | Description |
|-----|---------|-------------|
| `color-border` | `#dde` | Table and card border |
| `color-th-bg` | `#f0f2f5` | Table header cell background |
| `color-tr-hover-bg` | `#f5f8ff` | Table row hover background |
| `color-table-bg` | `#ffffff` | Table background |

#### Sidebar

| Key | Default | Description |
|-----|---------|-------------|
| `color-sidebar-label` | `#666666` | Sidebar section-label text |
| `color-sidebar-hover-bg` | `#e8f0fb` | Sidebar link hover background |
| `color-sidebar-current-bg` | `#dde8f8` | Currently-active sidebar item background |
| `color-sidebar-current-fg` | `#041e49` | Currently-active sidebar item text |

#### Parameter badges

Parameter badges display inline metadata such as whether a parameter is required, its position, or whether it is hidden. Badge text is always white.

| Key | Default | Description |
|-----|---------|-------------|
| `color-badge-required-bg` | `#c50f1f` | "Required" badge background |
| `color-badge-position-bg` | `#0078d4` | Positional parameter badge background |
| `color-badge-dontshow-bg` | `#999999` | "DontShow" badge background |

#### Footer

| Key | Default | Description |
|-----|---------|-------------|
| `color-footer-fg` | `#999999` | Footer text color |

---

### Typography

| Key | Default | Description |
|-----|---------|-------------|
| `font-body` | `'Segoe UI', Tahoma, Geneva, Verdana, sans-serif` | Body and UI font stack |
| `font-code` | `Consolas, 'Courier New', monospace` | Code and pre-formatted font stack |
