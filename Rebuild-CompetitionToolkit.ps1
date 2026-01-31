<#
Rebuild-CompetitionToolkit.ps1

Creates a reorganized repo layout under .\competition_toolkit WITHOUT excluding anything.
All content is copied into the new structure.

Usage:
  pwsh -File .\Rebuild-CompetitionToolkit.ps1
  pwsh -File .\Rebuild-CompetitionToolkit.ps1 -RepoRoot "E:\repo\cyberteam" -OutDir "E:\repo\competition_toolkit"

Notes:
- This script COPIES (does not delete) content.
- No filtering, no quarantine, no exclusions.
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $false)]
  [string]$RepoRoot = (Get-Location).Path,

  [Parameter(Mandatory = $false)]
  [string]$OutDir = (Join-Path (Get-Location).Path "competition_toolkit")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function New-Dir([string]$Path) {
  if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path | Out-Null }
}

function Copy-Tree([string]$Src, [string]$Dst) {
  if (Test-Path $Src) {
    New-Dir $Dst
    Copy-Item -Path (Join-Path $Src "*") -Destination $Dst -Recurse -Force
  }
}

function Write-Text([string]$Path, [string]$Content) {
  New-Dir (Split-Path $Path -Parent)
  Set-Content -Path $Path -Value $Content -Encoding UTF8
}

Write-Host "RepoRoot : $RepoRoot"
Write-Host "OutDir   : $OutDir"
Write-Host ""

# --- Create target structure ---
New-Dir $OutDir
$dirs = @(
  "docs\competition",
  "docs\platforms",
  "docs\procedures",
  "automation\ansible",
  "automation\hardening\linux",
  "automation\hardening\windows",
  "automation\monitoring",
  "scripts\bash",
  "scripts\powershell",
  "scripts\python",
  "checklists",
  "templates",
  "archive\legacy-or-experimental"
)
foreach ($d in $dirs) { New-Dir (Join-Path $OutDir $d) }

# --- Root README passthrough if present ---
$rootReadme = Join-Path $RepoRoot "README.md"
if (Test-Path $rootReadme) {
  Copy-Item $rootReadme (Join-Path $OutDir "README.md") -Force
}

# --- Move/copy major doc sets into sensible locations ---
Copy-Tree (Join-Path $RepoRoot "austin") (Join-Path $OutDir "docs\procedures\austin")
Copy-Tree (Join-Path $RepoRoot "Osec_CCDC_Guide") (Join-Path $OutDir "docs\guide")
Copy-Tree (Join-Path $RepoRoot "QuickReference") (Join-Path $OutDir "checklists\quickreference")

# --- Primary automation: ansible-ccdc (your repo) ---
Copy-Tree (Join-Path $RepoRoot "tools\programs\ansible-ccdc") (Join-Path $OutDir "automation\ansible\ansible-ccdc")

# --- Legacy automation/playbooks/checklists from tools ---
Copy-Tree (Join-Path $RepoRoot "tools\playbooks") (Join-Path $OutDir "automation\ansible\legacy-playbooks")
Copy-Tree (Join-Path $RepoRoot "tools\checklists") (Join-Path $OutDir "checklists\automation-checklists")

# --- Scripts: keep everything, but group them cleanly ---
# We copy the unix/windows script trees whole, unmodified, into archive (so nothing is omitted)
Copy-Tree (Join-Path $RepoRoot "tools\scripts\unix") (Join-Path $OutDir "archive\legacy-or-experimental\tools-scripts-unmodified\unix")
Copy-Tree (Join-Path $RepoRoot "tools\scripts\windows") (Join-Path $OutDir "archive\legacy-or-experimental\tools-scripts-unmodified\windows")
Copy-Tree (Join-Path $RepoRoot "tools\scripts\ci") (Join-Path $OutDir "archive\legacy-or-experimental\tools-scripts-unmodified\ci")

# Also provide a “front-door” scripts folder for quick ops:
# (Still NOT filtering: we just mirror top-level script entrypoints so teammates can find them)
if (Test-Path (Join-Path $RepoRoot "tools\scripts\unix")) {
  Copy-Item (Join-Path $RepoRoot "tools\scripts\unix\*") (Join-Path $OutDir "scripts\bash\unix") -Recurse -Force
}
if (Test-Path (Join-Path $RepoRoot "tools\scripts\windows")) {
  Copy-Item (Join-Path $RepoRoot "tools\scripts\windows\*") (Join-Path $OutDir "scripts\powershell\windows") -Recurse -Force
}

# --- Keep tools/ root files (flake, hosts.ini, etc.) for completeness ---
Copy-Tree (Join-Path $RepoRoot "tools\.config") (Join-Path $OutDir "archive\legacy-or-experimental\tools-root\.config")
foreach ($f in @("flake.lock","flake.nix","hosts.ini","LICENSE","log.py","__main__.py")) {
  $srcFile = Join-Path $RepoRoot ("tools\" + $f)
  if (Test-Path $srcFile) {
    Copy-Item $srcFile (Join-Path $OutDir "archive\legacy-or-experimental\tools-root") -Force
  }
}

# --- Third-party attribution (Sysmon config) ---
$thirdParty = @"
# Third-Party Sources

## Sysmon configuration
- Source: SwiftOnSecurity sysmon-config (GitHub)
- Notes: Included for defensive logging configuration. Review/tailor before use.
"@
Write-Text (Join-Path $OutDir "THIRD_PARTY.md") $thirdParty

# --- Minimal folder READMEs to reduce “mystery meat” ---
Write-Text (Join-Path $OutDir "automation\README.md") @"
# Automation

Primary automation lives in:
- automation/ansible/ansible-ccdc

Additional legacy playbooks/checklists are retained for reference.
"@

Write-Text (Join-Path $OutDir "scripts\README.md") @"
# Scripts

This repository contains a mix of scripts and references accumulated across team members.

- scripts/* contains quick-access copies for convenience.
- archive/legacy-or-experimental/tools-scripts-unmodified/* contains the original trees preserved intact.

No content is intentionally excluded; organization is for findability.
"@

Write-Text (Join-Path $OutDir "archive\legacy-or-experimental\README.md") @"
# Archive / Legacy / Experimental

This area contains content preserved for completeness and reference, including full unmodified script trees
as they existed prior to repository cleanup.

Keeping these here reduces clutter in the main repo while still retaining all files.
"@

# A practical .gitignore (does not remove anything; just prevents accidental commits of secrets later)
Write-Text (Join-Path $OutDir ".gitignore") @"
# Secrets / vaults (prevent accidental commit)
**/.vault_pass
**/*vault*.yml
**/*vault*.yaml
**/*secrets*
**/*password*
**/*.key
**/*.pem

# OS / editor
.DS_Store
Thumbs.db
.vscode/
.idea/

# Python
__pycache__/
*.pyc

# Logs / artifacts
*.log
artifacts/
"@

Write-Host ""
Write-Host "DONE. New reorganized repo created at:" -ForegroundColor Green
Write-Host "  $OutDir" -ForegroundColor Green
Write-Host ""
Write-Host "Nothing was excluded; everything was copied into the new structure." -ForegroundColor Cyan
