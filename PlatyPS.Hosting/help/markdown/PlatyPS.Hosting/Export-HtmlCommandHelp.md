---
document type: cmdlet
external help file: PlatyPS.Hosting-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PlatyPS.Hosting
ms.date: 03/19/2026
PlatyPS schema version: 2024-05-01
title: Export-HtmlCommandHelp
---

# Export-HtmlCommandHelp

## SYNOPSIS

Custom HTML renderer for PlatyPS CommandHelp objects.

## SYNTAX

### __AllParameterSets

```
Export-HtmlCommandHelp [-OutputFolder] <string> -CommandHelp <CommandHelp[]> [-Force] [-PassThru]
 [-ThemeFile <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Demonstrates how to build a custom renderer using the PlatyPS v1 object model.
PlatyPS ships built-in renderers for Markdown, YAML, and MAML.
 This script
shows how to consume CommandHelp objects straight off the pipeline and emit
any arbitrary output format – in this case self-contained HTML files that match
what Get-Help would display, but in a browser-friendly layout.

Pipeline pattern (mirrors the built-in Export-* cmdlets):

    # From live reflection
    New-CommandHelp -CommandInfo (Get-Command -Module MyModule) |
        Export-HtmlCommandHelp -OutputFolder .\html

    # From existing Markdown
    Measure-PlatyPSMarkdown -Path .\docs\*.md |
        Where-Object Filetype -match 'CommandHelp' |
        Import-MarkdownCommandHelp -Path { $_.FilePath } |
        Export-HtmlCommandHelp -OutputFolder .\html

## EXAMPLES

### EXAMPLE 1

Get-Command -Module Microsoft.PowerShell.Utility |
    Select-Object -First 5 |
    New-CommandHelp |
    .\Export-HtmlCommandHelp.ps1 -OutputFolder .\html -Force

### EXAMPLE 2

Import-MarkdownCommandHelp -Path .\docs\MyModule\Get-Widget.md |
    .\Export-HtmlCommandHelp.ps1 -OutputFolder .\html -PassThru

## PARAMETERS

### -CommandHelp

One or more Microsoft.PowerShell.PlatyPS.Model.CommandHelp objects.
Accepts pipeline input.

```yaml
Type: Microsoft.PowerShell.PlatyPS.Model.CommandHelp[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- cf
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

### -Force

Overwrite existing files without prompting.

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

### -OutputFolder

Root folder for the HTML files.
 A sub-folder named after the module is
created automatically, mirroring the convention used by Export-MarkdownCommandHelp.

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

### -PassThru

Emit the generated FileInfo objects to the pipeline.

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

### -ThemeFile

Path to a .psd1 theme file.
 Any keys present in the file override the
built-in defaults; missing keys keep their default values.
Copy themes\Default.psd1 from the module directory to get started.

```yaml
Type: System.String
DefaultValue: ''
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

### -WhatIf

Runs the command in a mode that only reports what would happen without performing the actions.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- wi
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Microsoft.PowerShell.PlatyPS.Model.CommandHelp[]

{{ Fill in the Description }}

## OUTPUTS

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

