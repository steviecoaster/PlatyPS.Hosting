---
document type: cmdlet
external help file: PlatyPS.Hosting-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PlatyPS.Hosting
ms.date: 03/19/2026
PlatyPS schema version: 2024-05-01
title: Publish-ModuleHelp
---

# Publish-ModuleHelp

## SYNOPSIS

Publishes PowerShell module HTML help files to an IIS web server.

## SYNTAX

### __AllParameterSets

```
Publish-ModuleHelp [[-SiteName] <string>] [[-SiteRoot] <string>] [[-HelpContent] <string[]>]
 [[-Computername] <string>] [[-Credential] <pscredential>] [-Force] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Publish-ModuleHelp stops the specified IIS website and copies the provided HTML
help content to the site's root directory.
Use this function after generating HTML
help with Export-HtmlCommandHelp to deploy the output to a local or remote IIS site.

## EXAMPLES

### EXAMPLE 1

Publish-ModuleHelp -SiteName MyDocsSite -SiteRoot C:\moduledocs\mydocssite -HelpContent .\help\html\MyModule

Stops the MyDocsSite IIS site and copies the HTML help files from the local
.\help\html\MyModule folder to C:\moduledocs\mydocssite.

### EXAMPLE 2

Publish-ModuleHelp -SiteName MyDocsSite -SiteRoot C:\moduledocs\mydocssite -HelpContent .\help\html\MyModule -Force

Stops the MyDocsSite IIS site and copies the HTML help files, overwriting any
existing files in the destination.

### EXAMPLE 3

Publish-ModuleHelp -SiteName MyDocsSite -SiteRoot C:\moduledocs\mydocssite -HelpContent .\help\html\MyModule -Computername webserver01 -Credential (Get-Credential)

Stops the MyDocsSite IIS site on the remote computer webserver01 and copies the
HTML help files, authenticating with the provided credentials.

## PARAMETERS

### -Computername

The name of the remote computer hosting the IIS site.
When specified, the
operation is performed on the remote machine using Invoke-Command.
If omitted,
the operation runs locally.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 3
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Credential

The credentials to use when connecting to the remote computer specified by
Computername.
If not provided, the current user's credentials are used.

```yaml
Type: System.Management.Automation.PSCredential
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 4
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Force

When specified, overwrites existing files in the destination without prompting.

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

### -HelpContent

One or more paths to the HTML help files or folders to copy to the site root.

```yaml
Type: System.String[]
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

### -SiteName

The name of the IIS site to publish help content to.
The site will be stopped
before the content is copied.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -SiteRoot

The file system path to the root folder of the IIS site where the help content
will be copied.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
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

- [Export-HtmlCommandHelp]()
- [New-ModuleHelp]()
