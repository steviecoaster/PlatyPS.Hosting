function Write-Section {
    param(
        [string] $Title,
        [string] $Content,
        [string] $Id = ($Title.ToLower() -replace '\s','-')
    )
    @"
        <section id="$Id">
            <h2>$Title</h2>
            $Content
        </section>
"@
}
