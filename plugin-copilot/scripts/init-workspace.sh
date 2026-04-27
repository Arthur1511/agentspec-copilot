#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# AgentSpec Workspace Initializer
# =============================================================================
# Creates SDD workspace directories in the user's project if they don't exist.
# Runs on SessionStart — idempotent, silent on success.
# =============================================================================

# Only create if we're in a git repo or project directory
if [[ -d ".git" ]] || [[ -f "copilot-instructions.md" ]] || [[ -d ".github" ]]; then
    mkdir -p .github/sdd/features || true
    mkdir -p .github/sdd/reports  || true
    mkdir -p .github/sdd/archive  || true
fi
