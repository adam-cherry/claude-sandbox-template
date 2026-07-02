---
name: powershell
description: "Develop PowerShell automation scripts following Microsoft best practices. Use when writing PowerShell code, designing script parameters, handling errors, working with REST APIs, processing files/data, or structuring script output. Covers param design, pipeline handling, error management, JSON output patterns, and credential handling for automation contexts. Use this skill even for short scripts — parameter validation and error handling patterns matter at every scale."
---

# PowerShell — Automation Scripts

Write production-quality PowerShell automation scripts using Microsoft best practices.

## Script Structure

```powershell
#Requires -Version 5.1

<#
.SYNOPSIS
    Brief description.
.DESCRIPTION
    Detailed description.
.PARAMETER Name
    Parameter description.
.EXAMPLE
    .\Script.ps1 -Name 'Value'
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,

    [int]$Count = 1,

    [switch]$Force
)

# --- Main Logic ---
try {
    # Implementation
    $result = @{
        success = $true
        data    = "Processed $Name"
    }
}
catch {
    $result = @{
        success = $false
        error   = $_.Exception.Message
    }
}

# Structured output
$result | ConvertTo-Json -Depth 10
```

## Parameter Design

Strong typing with validation — the param block is the contract for script inputs.

```powershell
param(
    # Required with validation
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,

    # Constrained choices
    [ValidateSet('Dev', 'Staging', 'Prod')]
    [string]$Environment = 'Dev',

    # Range validation
    [ValidateRange(1, 100)]
    [int]$RetryCount = 3,

    # Path that must exist
    [ValidateScript({ Test-Path $_ })]
    [string]$InputPath,

    # Boolean flag
    [switch]$DryRun
)
```

Use `PascalCase` for parameter names. Prefer descriptive names — `$SourcePath` not `$sp`.

## Error Handling

```powershell
try {
    $response = Invoke-RestMethod -Uri $uri -ErrorAction Stop
}
catch [System.Net.WebException] {
    Write-Error "Network error: $($_.Exception.Message)"
    return @{ success = $false; error = "network_error" }
}
catch [System.IO.FileNotFoundException] {
    Write-Error "File not found: $Path"
    return @{ success = $false; error = "file_not_found" }
}
catch {
    Write-Error "Unexpected error: $_"
    throw
}
```

`-ErrorAction Stop` converts non-terminating errors into catchable exceptions. Always use it with cmdlets inside try/catch blocks — without it, errors slip past silently.

## JSON Output

Automation scripts typically return structured data. PowerShell's JSON handling has quirks worth knowing.

```powershell
$result = @{
    success   = $true
    items     = @($processedItems)
    count     = $processedItems.Count
    timestamp = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
}

# -Depth is critical — default is only 2 levels
$result | ConvertTo-Json -Depth 10

# File-based output (for runners/orchestrators that read result files)
$result | ConvertTo-Json -Depth 10 | Out-File -FilePath ./result.json
```

**Gotcha — Depth**: `ConvertTo-Json` defaults to depth 2. Nested objects beyond that become type strings like `System.Collections.Hashtable`. Always pass `-Depth`.

**Gotcha — Single-element arrays**: Lose their array wrapper in JSON. Force with `@()`:
```powershell
$items = @($singleItem)  # Stays array even with 1 element
```

## REST API Calls

```powershell
# GET with auth
$headers = @{
    'Authorization' = "Bearer $Token"
    'Accept'        = 'application/json'
}
$response = Invoke-RestMethod -Uri $uri -Headers $headers -ErrorAction Stop

# POST with JSON body
$body = @{
    name  = $Name
    value = $Value
} | ConvertTo-Json

$params = @{
    Uri         = $uri
    Method      = 'Post'
    Body        = $body
    ContentType = 'application/json'
    Headers     = $headers
    ErrorAction = 'Stop'
}
$response = Invoke-RestMethod @params
```

Use `Invoke-RestMethod` — it auto-parses JSON responses. Only fall back to `Invoke-WebRequest` when you need raw response headers or status codes.

## File Operations

```powershell
# CSV with explicit delimiter and encoding
$data = Import-Csv -Path $InputPath -Delimiter ';' -Encoding UTF8

# Transform and export
$data | Where-Object { $_.Status -eq 'Active' } |
    Select-Object Name, Email, @{N='FullName'; E={"$($_.FirstName) $($_.LastName)"}} |
    Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

# JSON files
$config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
$config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Encoding UTF8
```

Always specify `-Encoding UTF8` for file operations — default encoding varies across PS versions and can introduce BOM issues.

## Credential Handling

Never hardcode secrets. Use a cascade: parameter → environment → fail with warning.

```powershell
param(
    [string]$ApiToken = ""
)

# Cascade: param > env > warning
if (-not $ApiToken) { $ApiToken = $env:API_TOKEN }
if (-not $ApiToken) {
    Write-Warning "No API token provided. Set -ApiToken or API_TOKEN env var."
    $ApiToken = "not-configured"
}
```

This pattern lets scripts run in demo/test mode without credentials while making it obvious that real credentials are missing.

## Splatting

Use splatting for readability when cmdlets accumulate parameters.

```powershell
$mailParams = @{
    From       = 'noreply@example.com'
    To         = $Recipients
    Subject    = "Report — $(Get-Date -Format 'yyyy-MM-dd')"
    Body       = $htmlBody
    BodyAsHtml = $true
    SmtpServer = $env:SMTP_HOST
    ErrorAction = 'Stop'
}
Send-MailMessage @mailParams
```

## Output Patterns

Automation scripts serve two audiences: humans watching the console and machines parsing the result. Use `Write-Host` for progress and `ConvertTo-Json` for the structured result.

```powershell
# Progress for humans
Write-Host "[OK]    $endpoint ($($elapsed)ms)"

# Structured result for machines
$result | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8

# Also emit to stdout so callers can capture it
$result | ConvertTo-Json -Depth 10
```

Create output directories before writing — scripts shouldn't assume they exist:
```powershell
$outputDir = Split-Path -Parent $OutputPath
if ($outputDir -and -not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}
```

## Cross-Platform

PowerShell 7+ runs on macOS, Linux, and Windows. Platform-specific logic needs version guards because `$IsMacOS`/`$IsWindows` only exist in PS 6+.

```powershell
if ($PSVersionTable.PSVersion.Major -ge 6) {
    # PS 7+: use automatic variables
    if ($IsMacOS) { <# macOS path #> }
    elseif ($IsLinux) { <# Linux path #> }
    else { <# Windows path #> }
} else {
    # PS 5.1: always Windows
}
```

## Timing

Use `Stopwatch` to measure operations — more precise than comparing `Get-Date` timestamps:
```powershell
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
# ... operation ...
$stopwatch.Stop()
Write-Host "Completed in $($stopwatch.ElapsedMilliseconds)ms"
```

## Key Conventions

| Pattern | Rule |
|---------|------|
| Naming | **Verb-Noun** for functions — use approved verbs (`Get-Verb`) |
| Destructive ops | Add `[CmdletBinding(SupportsShouldProcess)]` for `-WhatIf`/`-Confirm` |
| Pipeline input | `[Parameter(ValueFromPipeline)]` when processing collections |
| Exit codes | `exit 0` success, `exit 1` failure — important for CI/CD and orchestrators |
| Encoding | Always `-Encoding UTF8` on file operations |
| Comparison | Use `-eq`, `-ne`, `-like`, `-match` — not `==` or `!=` |
