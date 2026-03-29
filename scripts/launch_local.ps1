$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Split-Path -Parent $ScriptDir
$HostName = "127.0.0.1"
$PreferredPorts = @(4173, 4174, 4175, 8080, 8000)

function Get-FreePort {
  foreach ($Port in $PreferredPorts) {
    $Listener = $null
    try {
      $Listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Parse($HostName), $Port)
      $Listener.Start()
      $Listener.Stop()
      return $Port
    } catch {
      if ($Listener -ne $null) {
        $Listener.Stop()
      }
    }
  }

  throw "No free local port was found."
}

function Get-MimeType([string]$Path) {
  switch ([System.IO.Path]::GetExtension($Path).ToLowerInvariant()) {
    ".css" { return "text/css; charset=utf-8" }
    ".html" { return "text/html; charset=utf-8" }
    ".ico" { return "image/x-icon" }
    ".js" { return "application/javascript; charset=utf-8" }
    ".json" { return "application/json; charset=utf-8" }
    ".png" { return "image/png" }
    ".svg" { return "image/svg+xml" }
    ".txt" { return "text/plain; charset=utf-8" }
    ".webmanifest" { return "application/manifest+json" }
    default { return "application/octet-stream" }
  }
}

function Open-Browser([string]$Url) {
  if ($env:NO_OPEN_BROWSER -match "^(1|true|yes)$") {
    return
  }

  try {
    Start-Process "microsoft-edge:$Url" | Out-Null
    return
  } catch {
  }

  try {
    Start-Process $Url | Out-Null
  } catch {
  }
}

function Send-TextResponse($Response, [int]$StatusCode, [string]$Message) {
  $Bytes = [System.Text.Encoding]::UTF8.GetBytes($Message)
  $Response.StatusCode = $StatusCode
  $Response.ContentType = "text/plain; charset=utf-8"
  $Response.ContentLength64 = $Bytes.Length
  $Response.OutputStream.Write($Bytes, 0, $Bytes.Length)
}

$Port = Get-FreePort
$Url = "http://${HostName}:${Port}/"
$RootFull = ([System.IO.Path]::GetFullPath($Root)).TrimEnd("\") + "\"
$Http = [System.Net.HttpListener]::new()
$Http.Prefixes.Add($Url)
$Http.Start()

Write-Host ""
Write-Host "daniel-caliboo"
Write-Host "Root: $Root"
Write-Host "URL: $Url"
Write-Host "Open this in Chrome or Edge."
Write-Host ""
Write-Host "Keep this window open while you work."
Write-Host "Press Ctrl + C to stop the local server."
Write-Host ""

Open-Browser $Url

try {
  while ($Http.IsListening) {
    $Context = $Http.GetContext()
    $Request = $Context.Request
    $Response = $Context.Response

    $Response.AddHeader("Cache-Control", "no-store, no-cache, must-revalidate")
    $Response.AddHeader("Pragma", "no-cache")
    $Response.AddHeader("Expires", "0")

    try {
      if ($Request.HttpMethod -notin @("GET", "HEAD")) {
        Send-TextResponse $Response 405 "Method not allowed."
        continue
      }

      $RequestPath = [System.Uri]::UnescapeDataString($Request.Url.AbsolutePath.TrimStart("/"))
      if ([string]::IsNullOrWhiteSpace($RequestPath)) {
        $RequestPath = "index.html"
      }

      $LocalPath = Join-Path $Root $RequestPath
      $ResolvedPath = [System.IO.Path]::GetFullPath($LocalPath)

      if ($ResolvedPath -notlike "$RootFull*" -and $ResolvedPath -ne $RootFull.TrimEnd("\")) {
        Send-TextResponse $Response 403 "Forbidden."
        continue
      }

      if (Test-Path -LiteralPath $ResolvedPath -PathType Container) {
        $ResolvedPath = Join-Path $ResolvedPath "index.html"
      }

      if (-not (Test-Path -LiteralPath $ResolvedPath -PathType Leaf)) {
        Send-TextResponse $Response 404 "Not found."
        continue
      }

      $Bytes = [System.IO.File]::ReadAllBytes($ResolvedPath)
      $Response.StatusCode = 200
      $Response.ContentType = Get-MimeType $ResolvedPath
      $Response.ContentLength64 = $Bytes.Length

      if ($Request.HttpMethod -ne "HEAD") {
        $Response.OutputStream.Write($Bytes, 0, $Bytes.Length)
      }
    } catch {
      Send-TextResponse $Response 500 "Internal server error."
    } finally {
      $Response.OutputStream.Close()
    }
  }
} finally {
  if ($Http.IsListening) {
    $Http.Stop()
  }
  $Http.Close()
}
