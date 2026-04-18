$ErrorActionPreference = 'Stop'

$base = Split-Path -Parent $MyInvocation.MyCommand.Path
$distributionPath = Join-Path $base 'distribution.json'

if (!(Test-Path $distributionPath)) {
  throw "distribution.json not found at $distributionPath"
}

$distribution = Get-Content $distributionPath -Raw | ConvertFrom-Json

Write-Host "== Local files check ==" -ForegroundColor Cyan

$requiredDirs = @(
  'mobile/cache',
  'mobile/cache_snow',
  'mobile/launcher'
)

foreach ($dir in $requiredDirs) {
  $path = Join-Path $base $dir
  if (Test-Path $path -PathType Container) {
    Write-Host "[OK] $dir"
  } else {
    Write-Host "[MISS] $dir" -ForegroundColor Red
  }
}

foreach ($entry in $distribution.cache) {
  $filePath = Join-Path $base ("mobile/cache/" + $entry.path + "/" + $entry.name)
  $exists = Test-Path $filePath -PathType Leaf
  if (!$exists) {
    Write-Host "[MISS] $filePath" -ForegroundColor Red
    continue
  }

  $size = (Get-Item $filePath).Length
  $expected = [int64]$entry.bytes[0]
  if ($size -eq $expected) {
    Write-Host "[OK]   $filePath ($size bytes)"
  } else {
    Write-Host "[SIZE] $filePath local=$size expected=$expected" -ForegroundColor Yellow
  }
}

$snowEntries = $distribution.cache | Where-Object { $_.bytes.Count -gt 1 }
foreach ($entry in $snowEntries) {
  $filePath = Join-Path $base ("mobile/cache_snow/" + $entry.path + "/" + $entry.name)
  $exists = Test-Path $filePath -PathType Leaf
  if (!$exists) {
    Write-Host "[MISS] $filePath" -ForegroundColor Red
    continue
  }

  $size = (Get-Item $filePath).Length
  $expected = [int64]$entry.bytes[1]
  if ($size -eq $expected) {
    Write-Host "[OK]   $filePath ($size bytes)"
  } else {
    Write-Host "[SIZE] $filePath local=$size expected=$expected" -ForegroundColor Yellow
  }
}

$apkPath = Join-Path $base ("mobile/launcher/" + $distribution.launcher.name)
if (Test-Path $apkPath -PathType Leaf) {
  $size = (Get-Item $apkPath).Length
  $expected = [int64]$distribution.launcher.bytes
  if ($size -eq $expected) {
    Write-Host "[OK]   $apkPath ($size bytes)"
  } else {
    Write-Host "[SIZE] $apkPath local=$size expected=$expected" -ForegroundColor Yellow
  }
} else {
  Write-Host "[MISS] $apkPath" -ForegroundColor Red
}

Write-Host "`n== Endpoint check ==" -ForegroundColor Cyan

$hostBase = 'http://127.0.0.1:3000'
$urls = @(
  "$hostBase/distribution.json",
  "$hostBase/api/launcher/news",
  "$hostBase/api/launcher/donate"
)

foreach ($entry in $distribution.cache) {
  $urls += "$hostBase/mobile/cache/$($entry.path)/$($entry.name)"
}

foreach ($entry in $snowEntries) {
  $urls += "$hostBase/mobile/cache_snow/$($entry.path)/$($entry.name)"
}

$urls += "$hostBase/mobile/launcher/$($distribution.launcher.name)"

$seen = @{}
foreach ($url in $urls) {
  if ($seen.ContainsKey($url)) { continue }
  $seen[$url] = $true
  try {
    $res = Invoke-WebRequest -Uri $url -Method Head -UseBasicParsing -TimeoutSec 10
    Write-Host "[HTTP $($res.StatusCode)] $url"
  } catch {
    $code = $_.Exception.Response.StatusCode.value__
    if ($code) {
      Write-Host "[HTTP $code] $url" -ForegroundColor Red
    } else {
      Write-Host "[NETERR] $url :: $($_.Exception.Message)" -ForegroundColor Red
    }
  }
}

