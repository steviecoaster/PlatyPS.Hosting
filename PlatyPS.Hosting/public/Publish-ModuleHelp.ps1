function Publish-ModuleHelp {
    <#
        .SYNOPSIS
        Publishes PowerShell module HTML help files to an IIS web server.

        .DESCRIPTION
        Publish-ModuleHelp stops the specified IIS website and copies the provided HTML
        help content to the site's root directory. Use this function after generating HTML
        help with Export-HtmlCommandHelp to deploy the output to a local or remote IIS site.

        .PARAMETER SiteName
        The name of the IIS site to publish help content to. The site will be stopped
        before the content is copied.

        .PARAMETER SiteRoot
        The file system path to the root folder of the IIS site where the help content
        will be copied.

        .PARAMETER HelpContent
        One or more paths to the HTML help files or folders to copy to the site root.

        .PARAMETER Computername
        The name of the remote computer hosting the IIS site. When specified, the
        operation is performed on the remote machine using Invoke-Command. If omitted,
        the operation runs locally.

        .PARAMETER Credential
        The credentials to use when connecting to the remote computer specified by
        Computername. If not provided, the current user's credentials are used.

        .PARAMETER Force
        When specified, overwrites existing files in the destination without prompting.

        .EXAMPLE
        Publish-ModuleHelp -SiteName MyDocsSite -SiteRoot C:\moduledocs\mydocssite -HelpContent .\help\html\MyModule

        Stops the MyDocsSite IIS site and copies the HTML help files from the local
        .\help\html\MyModule folder to C:\moduledocs\mydocssite.

        .EXAMPLE
        Publish-ModuleHelp -SiteName MyDocsSite -SiteRoot C:\moduledocs\mydocssite -HelpContent .\help\html\MyModule -Force

        Stops the MyDocsSite IIS site and copies the HTML help files, overwriting any
        existing files in the destination.

        .EXAMPLE
        Publish-ModuleHelp -SiteName MyDocsSite -SiteRoot C:\moduledocs\mydocssite -HelpContent .\help\html\MyModule -Computername webserver01 -Credential (Get-Credential)

        Stops the MyDocsSite IIS site on the remote computer webserver01 and copies the
        HTML help files, authenticating with the provided credentials.
    #>
    [CmdletBinding(HelpUri='https://steviecoaster.github.io/PlatyPS.Hosting/PlatyPS.Hosting/Publish-ModuleHelp/')]
    Param(
        [Parameter()]
        [String]
        $SiteName,

        [Parameter()]
        [String]
        $SiteRoot,

        [Parameter()]
        [String[]]
        $HelpContent,

        [Parameter()]
        [String]
        $Computername,

        [Parameter()]
        [PSCredential]
        $Credential,

        [Parameter()]
        [Switch]
        $Force
    )

    if (-not $Computername) {
        Stop-Website -Name $SiteName

        Copy-Item $HelpContent -Destination $SiteRoot -Force:$($Force.IsPresent)

        Start-Website -Name $SiteName
    }
    else {
        $sessionParams = @{
            ComputerName = $Computername
        }
        if ($Credential) {
            $sessionParams['Credential'] = $Credential
        }

        $session = New-PSSession @sessionParams

        # Copy local files into the remote SiteRoot
        Copy-Item $HelpContent -Destination $SiteRoot -ToSession $session -Recurse -Force:$($Force.IsPresent)

        # Then stop/start the site remotely
        Invoke-Command -Session $session -ScriptBlock {
            Stop-Website -Name $using:SiteName
            # Files already copied, just restart the site
            Start-Website -Name $using:SiteName
        }

        Remove-PSSession $session
    }
    
}