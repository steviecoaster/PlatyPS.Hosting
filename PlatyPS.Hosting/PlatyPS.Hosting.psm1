$private = Get-ChildItem (Join-Path $PSScriptRoot 'private') -Filter *.ps1
$public  = Get-ChildItem (Join-Path $PSScriptRoot 'public')  -Filter *.ps1

$private + $public | ForEach-Object {
    . $_.FullName
}
