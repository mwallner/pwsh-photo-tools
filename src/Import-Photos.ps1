[CmdletBinding()]
param(
  [string] $SourceFolder,
  [string[]] $IncludeFilter = @("*.jpg", "*.nef"),
  [string] $DestinationBase,
  [string] $ImportPathFormat = "yyyy\/MM\/dd",
  [switch] $Recurse,
  [switch] $noop
)
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName 'System.Drawing'
Import-Module ".\lib\ExifDateTime\ExifDateTime.psm1"

$gciArgs = @{
  Path    = $SourceFolder
  Include = $IncludeFilter
  Recurse = $Recurse
}

Get-ChildItem @gciArgs | Where-Object { -Not $_.PSIsContainer } | Foreach-Object {
  $i = Get-ExifDateTaken -Path $_.FullName -Verbose:$VerbosePreference 
  Write-Verbose "processing $($i.Path), date taken: ${i.ExifDateTaken} ..."
  if (-Not $i.ExifDateTaken) {
    Write-Host " (EE) -> failed to get 'DateTaken' from $_ -> skipping this file!"
    return
  }
  $importSubDir = Get-Date -Date $i.ExifDateTaken -Format $ImportPathFormat
  $outFolder = Join-Path $DestinationBase $importSubDir

  if (-Not (Test-Path $outFolder)) {
    Write-Host " (i) target folder $outFolder does not yet exist! - creating!"
    if (-Not $noop) {
      New-Item -ItemType Directory -Path $outFolder -Force | Out-Null
    }
  }

  $outFile = Join-Path $outFolder $_.Name
  Write-Verbose " > target file: $outFile"

  if (Test-Path $outFile) {
    Write-Host " (W) $outFile already exist - SKIP!"
  }
  else {
    Write-Host " (i) $_ -> $outFile"
    if (-Not $noop) {
      Copy-Item -Path $_.FullName -Destination $outFile
    }
  }
}


