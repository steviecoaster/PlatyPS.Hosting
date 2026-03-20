---
document type: cmdlet
external help file: PlatyPS.Hosting-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PlatyPS.Hosting
ms.date: 03/19/2026
PlatyPS schema version: 2024-05-01
title: New-ModuleHelp
---

# New-ModuleHelp

## SYNOPSIS

Generates all help artifacts for a loaded module in one step.

## SYNTAX

### __AllParameterSets

```
New-ModuleHelp [-ModuleName] <string> [-OutputFolder] <string> [[-ThemeFile] <string>] [-Html]
 [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

New-ModuleHelp builds three help outputs from a single reflection pass
against a loaded module, writing each into its own sub-folder under
OutputFolder:

1.
MAML  (<OutputFolder>\maml\<ModuleName>\)
   Updateable XML help suitable for packaging inside the module or
   distributing via Save-Help / Update-Help.
 Generated with
   Export-MamlCommandHelp.

2.
Markdown  (<OutputFolder>\markdown\<ModuleName>\)
   Human-readable source files that should be kept in version control
   and hand-edited to add descriptions, examples, and notes.
   Generated with New-MarkdownCommandHelp (including a module page).
   On subsequent runs, use Update-MarkdownCommandHelp instead so that
   hand-written content is preserved.

3.
HTML  (<OutputFolder>\html\<ModuleName>\)  [optional, -Html switch]
   A static website built on top of the PlatyPS CommandHelp object
   model using the custom Export-HtmlCommandHelp renderer.
 HTML is
   generated from the Markdown files rather than from live reflection,
   so hand-edited descriptions, examples, and notes are included.

## EXAMPLES

### EXAMPLE 1

Import-Module MyModule
New-ModuleHelp -ModuleName MyModule -OutputFolder .\docs

Generates MAML and Markdown help for MyModule under .\docs\.

### EXAMPLE 2

Import-Module PowerShellUniversal.Plaster
New-ModuleHelp -ModuleName PowerShellUniversal.Plaster -OutputFolder .\docs -Html

Generates MAML, Markdown, and HTML help for the module.

## PARAMETERS

### -Html

When specified, a static HTML site is also produced in addition to
the MAML and Markdown outputs.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ModuleName

Name of the module to generate help for.
 The module must already be
loaded in the current session (Import-Module before calling this).

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -OutputFolder

Root folder that receives the generated artifacts.
 Created
automatically if it does not yet exist.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ThemeFile

Path to a .psd1 theme file passed through to Export-HtmlCommandHelp when
-Html is specified.
 Copy themes\Default.psd1 from the module directory
as a starting point.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 2
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

