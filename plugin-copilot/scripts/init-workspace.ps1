# =============================================================================
# AgentSpec Workspace Initializer (PowerShell)
# =============================================================================
# Creates SDD workspace directories in the user's project if they don't exist.
# Runs on sessionStart -- idempotent, silent on success.
# =============================================================================

if ((Test-Path '.git') -or (Test-Path 'copilot-instructions.md') -or (Test-Path '.github')) {
    New-Item -ItemType Directory -Force -Path '.github/sdd/features' | Out-Null
    New-Item -ItemType Directory -Force -Path '.github/sdd/reports'  | Out-Null
    New-Item -ItemType Directory -Force -Path '.github/sdd/archive'  | Out-Null
}
