#Requires -Version 5.1
<#
.SYNOPSIS
    AgentSpec Copilot CLI Plugin Builder

.DESCRIPTION
    Packages .github/ (source of truth for Copilot CLI) into plugin-copilot/
    (distributable plugin). Rewrites internal paths from .github/ to
    ${COPILOT_PLUGIN_ROOT}/ while preserving workspace paths
    (.github/sdd/features, reports, archive).

    Parallel to build-plugin.sh (Claude Code), which packages .claude/ -> plugin/.

.EXAMPLE
    .\build-copilot.ps1
    .\build-copilot.ps1 -Help
#>
[CmdletBinding()]
param(
    [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$SourceDir  = Join-Path $ScriptDir '.github'
$PluginDir  = Join-Path $ScriptDir 'plugin-copilot'

# --- Helpers ------------------------------------------------------------------

function Write-Info  ($msg) { Write-Host "[INFO] $msg"  -ForegroundColor Cyan }
function Write-Ok    ($msg) { Write-Host "[OK]   $msg"  -ForegroundColor Green }
function Write-Warn  ($msg) { Write-Host "[WARN] $msg"  -ForegroundColor Yellow }
function Write-Err   ($msg) { Write-Host "[ERROR] $msg" -ForegroundColor Red }

# Cleanup .tmp files on exit
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    Get-ChildItem -Path $PluginDir -Filter '*.tmp' -Recurse -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue
}

# --- Help ---------------------------------------------------------------------

if ($Help) {
    Write-Host @'
AgentSpec Copilot CLI Plugin Builder

Packages .github/ (source of truth) into plugin-copilot/ (distributable plugin).
Rewrites internal paths to ${COPILOT_PLUGIN_ROOT}/ and preserves workspace paths.

Usage:
  .\build-copilot.ps1           Build the plugin
  .\build-copilot.ps1 -Help     Show this help

Output: plugin-copilot/ directory ready for distribution as a gh extension.
'@
    exit 0
}

# --- Preflight ----------------------------------------------------------------

if (-not (Test-Path $SourceDir -PathType Container)) {
    Write-Err ".github/ directory not found at $SourceDir"
    exit 1
}

if (-not (Test-Path (Join-Path $SourceDir 'manifest.yaml'))) {
    Write-Err ".github/manifest.yaml not found. Create the manifest first."
    exit 1
}

if (-not (Test-Path (Join-Path $PluginDir '.claude-plugin\plugin.json'))) {
    Write-Err "plugin-copilot/.claude-plugin/plugin.json not found."
    Write-Err "Create the plugin manifest before building."
    exit 1
}

Write-Info "Building AgentSpec Copilot CLI plugin from .github/ ..."

# --- Step 1: Clean previous build ---------------------------------------------

Write-Info "Cleaning previous build..."
if (Test-Path $PluginDir) {
    # Preserve plugin-only artifacts not built from source
    Get-ChildItem -Path $PluginDir -Force |
        Where-Object { $_.Name -notin @('.claude-plugin', 'README.md', 'scripts', 'plugin.json') } |
        Remove-Item -Recurse -Force
} else {
    New-Item -ItemType Directory -Path $PluginDir | Out-Null
}
Write-Ok "Output directory ready: $PluginDir"

# --- Step 2: Copy components --------------------------------------------------

Write-Info "Copying agents..."
Copy-Item (Join-Path $SourceDir 'agents') (Join-Path $PluginDir 'agents') -Recurse

Write-Info "Copying skills..."
Copy-Item (Join-Path $SourceDir 'skills') (Join-Path $PluginDir 'skills') -Recurse

Write-Info "Copying KB domains..."
Copy-Item (Join-Path $SourceDir 'kb') (Join-Path $PluginDir 'kb') -Recurse

Write-Info "Copying SDD templates and architecture..."
$sddDest = Join-Path $PluginDir 'sdd'
New-Item -ItemType Directory -Path $sddDest -Force | Out-Null
Copy-Item (Join-Path $SourceDir 'sdd\templates')    (Join-Path $sddDest 'templates')    -Recurse
Copy-Item (Join-Path $SourceDir 'sdd\architecture') (Join-Path $sddDest 'architecture') -Recurse

Write-Info "Copying manifest..."
Copy-Item (Join-Path $SourceDir 'manifest.yaml') (Join-Path $PluginDir 'manifest.yaml')

Write-Info "Copying hooks..."
Copy-Item (Join-Path $SourceDir 'hooks') (Join-Path $PluginDir 'hooks') -Recurse

Write-Ok "All components copied"

# --- Step 3: Path rewriting ---------------------------------------------------
#
# REWRITE (plugin-internal references):
#   .github/kb/               -> ${COPILOT_PLUGIN_ROOT}/kb/
#   .github/agents/           -> ${COPILOT_PLUGIN_ROOT}/agents/
#   .github/skills/           -> ${COPILOT_PLUGIN_ROOT}/skills/
#   .github/sdd/templates/    -> ${COPILOT_PLUGIN_ROOT}/sdd/templates/
#   .github/sdd/architecture/ -> ${COPILOT_PLUGIN_ROOT}/sdd/architecture/
#
# PRESERVE (workspace output paths -- must NOT be rewritten):
#   .github/sdd/features/          -> stays as-is (user project workspace)
#   .github/sdd/reports/           -> stays as-is (user project workspace)
#   .github/sdd/archive/           -> stays as-is (user project workspace)
#   .github/copilot-instructions.md -> stays as-is (user project)
# -----------------------------------------------------------------------------

Write-Info "Rewriting paths in .md, .yaml, .yml, and .json files..."

$rewriteExts = @('*.md', '*.yaml', '*.yml', '*.json')
$rewriteFiles = Get-ChildItem -Path $PluginDir -Include $rewriteExts -Recurse -File

foreach ($file in $rewriteFiles) {
    $content = Get-Content $file.FullName -Raw
    $updated = $content `
        -replace [regex]::Escape('.github/kb/'),               '${COPILOT_PLUGIN_ROOT}/kb/' `
        -replace [regex]::Escape('.github/agents/'),           '${COPILOT_PLUGIN_ROOT}/agents/' `
        -replace [regex]::Escape('.github/skills/'),           '${COPILOT_PLUGIN_ROOT}/skills/' `
        -replace [regex]::Escape('.github/sdd/templates/'),    '${COPILOT_PLUGIN_ROOT}/sdd/templates/' `
        -replace [regex]::Escape('.github/sdd/architecture/'), '${COPILOT_PLUGIN_ROOT}/sdd/architecture/'
    if ($updated -ne $content) {
        Set-Content $file.FullName $updated -NoNewline -Encoding UTF8
    }
}

Write-Ok "Paths rewritten"

# --- Step 4: Restore workspace paths (over-rewritten by step 3) --------------
#
# Step 3 rewrites ALL .github/sdd/ references. features/reports/archive are
# workspace output paths that must remain as .github/sdd/<dir>/.
# -----------------------------------------------------------------------------

Write-Info "Restoring workspace output paths..."

$mdFiles = Get-ChildItem -Path $PluginDir -Filter '*.md' -Recurse -File
foreach ($file in $mdFiles) {
    $content = Get-Content $file.FullName -Raw
    $updated = $content `
        -replace [regex]::Escape('${COPILOT_PLUGIN_ROOT}/sdd/features/'), '.github/sdd/features/' `
        -replace [regex]::Escape('${COPILOT_PLUGIN_ROOT}/sdd/reports/'),  '.github/sdd/reports/' `
        -replace [regex]::Escape('${COPILOT_PLUGIN_ROOT}/sdd/archive/'),  '.github/sdd/archive/'
    if ($updated -ne $content) {
        Set-Content $file.FullName $updated -NoNewline -Encoding UTF8
    }
}

Write-Ok "Workspace paths restored"

# --- Step 5: Rewrite hardcoded absolute paths ---------------------------------

Write-Info "Rewriting absolute paths..."

$absFiles = Get-ChildItem -Path $PluginDir -Include @('*.md', '*.sh') -Recurse -File
foreach ($file in $absFiles) {
    $content = Get-Content $file.FullName -Raw
    $updated = $content `
        -replace '/[^ ]*\$\{COPILOT_PLUGIN_ROOT\}/',  '${COPILOT_PLUGIN_ROOT}/' `
        -replace '/[^ ]*/\.github/skills/',            '${COPILOT_PLUGIN_ROOT}/skills/' `
        -replace 'cd \.github/skills/',                'cd ${COPILOT_PLUGIN_ROOT}/skills/'
    if ($updated -ne $content) {
        Set-Content $file.FullName $updated -NoNewline -Encoding UTF8
    }
}

Write-Ok "Absolute paths rewritten"

# --- Step 6: Verify no stale .github/ paths remain ---------------------------

Write-Info "Verifying path migration..."

$allowedPatterns = @(
    'COPILOT_PLUGIN_ROOT',
    '.github/sdd/features',
    '.github/sdd/reports',
    '.github/sdd/archive',
    '.github/sdd/',
    '.github/storage',
    '.github/workflows/',
    '.github/commands/',
    '.github/copilot-instructions',
    '.github/CLAUDE.md',
    '.github/**',
    [char]9 + '#',   # tab + comment
    '    #',         # indented comment
    '├── .github'
)

$staleFiles = Get-ChildItem -Path $PluginDir -Include @('*.md', '*.yaml', '*.yml') -Recurse -File
$staleLines = [System.Collections.Generic.List[string]]::new()

foreach ($file in $staleFiles) {
    $lines = Get-Content $file.FullName
    foreach ($line in $lines) {
        if ($line -match '\.github/' -and -not ($allowedPatterns | Where-Object { $line -match [regex]::Escape($_) })) {
            $staleLines.Add("$($file.FullName):  $line")
        }
    }
}

if ($staleLines.Count -gt 0) {
    Write-Warn "$($staleLines.Count) potentially stale .github/ reference(s) found:"
    $staleLines | Select-Object -First 20 | ForEach-Object { Write-Host "  $_" }
    Write-Host ""
    Write-Warn "Review the above -- some may be intentional (workspace paths)."
} else {
    Write-Ok "No stale .github/ paths found"
}

# --- Step 7: Summary ----------------------------------------------------------

$agentCount = (Get-ChildItem -Path (Join-Path $PluginDir 'agents') -Filter '*.agent.md' -File -ErrorAction SilentlyContinue).Count
$skillCount = (Get-ChildItem -Path (Join-Path $PluginDir 'skills') -Filter 'SKILL.md' -Recurse -File -ErrorAction SilentlyContinue).Count
$kbCount    = (Get-ChildItem -Path (Join-Path $PluginDir 'kb') -Directory -ErrorAction SilentlyContinue |
               Where-Object { $_.Name -notin @('_templates', 'shared') }).Count

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "AgentSpec Copilot CLI Plugin Build Complete"  -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Agents:   $agentCount"
Write-Host "  Skills:   $skillCount"
Write-Host "  KB:       $kbCount domains"
Write-Host ""
Write-Host "  Output:   $PluginDir\"
Write-Host ""
Write-Host "  Distribute as a copilot cli plugin:"
Write-Host "    copilot plugin install ."
Write-Host ""
Write-Host "  Validate with:"
Write-Host "    cat $PluginDir\manifest.yaml"
Write-Host "============================================" -ForegroundColor Green
