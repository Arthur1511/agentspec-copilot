#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# AgentSpec Copilot CLI Plugin Builder
# =============================================================================
# Packages .github/ (source of truth for Copilot CLI) into plugin-copilot/
# (distributable plugin). Rewrites internal paths from .github/ to
# ${COPILOT_PLUGIN_ROOT}/ while preserving workspace paths
# (.github/sdd/features, reports, archive).
#
# Usage:
#   ./build-copilot.sh           # Build the plugin
#   ./build-copilot.sh --help    # Show this help
#
# Parallel to build-plugin.sh (Claude Code), which packages .claude/ -> plugin/.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${SCRIPT_DIR}/.github"
PLUGIN_DIR="${SCRIPT_DIR}/plugin-copilot"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { printf "${BLUE}[INFO]${NC} %s\n" "$1"; }
ok()    { printf "${GREEN}[OK]${NC} %s\n" "$1"; }
warn()  { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$1" >&2; }

# Cleanup trap for interrupted builds
cleanup() {
    find "${PLUGIN_DIR:-.}" -name "*.tmp" -type f -delete 2>/dev/null || true
}
trap cleanup EXIT

# --- Help --------------------------------------------------------------------

if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    cat <<'HELPEOF'
AgentSpec Copilot CLI Plugin Builder

Packages .github/ (source of truth) into plugin-copilot/ (distributable plugin).
Rewrites internal paths to ${COPILOT_PLUGIN_ROOT}/ and preserves workspace paths.

Usage:
  ./build-copilot.sh           Build the plugin
  ./build-copilot.sh --help    Show this help

Output: plugin-copilot/ directory ready for distribution as a gh extension.
HELPEOF
    exit 0
fi

# --- Preflight ---------------------------------------------------------------

if [[ ! -d "${SOURCE_DIR}" ]]; then
    error ".github/ directory not found at ${SOURCE_DIR}"
    exit 1
fi

if [[ ! -f "${SOURCE_DIR}/manifest.yaml" ]]; then
    error ".github/manifest.yaml not found. Create the manifest first."
    exit 1
fi

# if [[ ! -f "${PLUGIN_DIR}/.claude-plugin/plugin.json" ]]; then
#     error "plugin-copilot/.claude-plugin/plugin.json not found."
#     error "Create the plugin manifest before building."
#     exit 1
# fi

info "Building AgentSpec Copilot CLI plugin from .github/ ..."

# --- Step 0: Generate agent router ------------------------------------------

info "Generating agent router (step 0)..."
if ! python3 scripts/generate-agent-router.py; then
    error "Agent router generation failed. Fix scripts/generate-agent-router.py before building."
    exit 1
fi
ok "Agent router generated."

# --- Step 1: Clean previous build --------------------------------------------

info "Cleaning previous build..."
if [[ -d "${PLUGIN_DIR}" ]]; then
    # Selectively clean: preserve plugin-only artifacts not built from source
    find "${PLUGIN_DIR:?}" -mindepth 1 -maxdepth 1 \
        ! -name '.claude-plugin' \
        ! -name 'README.md' \
        ! -name 'scripts' \
        -exec rm -rf {} +
else
    mkdir -p "${PLUGIN_DIR}"
fi
ok "Output directory ready: ${PLUGIN_DIR}"

# --- Step 2: Copy components -------------------------------------------------

info "Copying agents..."
cp -r "${SOURCE_DIR}/agents" "${PLUGIN_DIR}/agents"

info "Copying skills..."
cp -r "${SOURCE_DIR}/skills" "${PLUGIN_DIR}/skills"

info "Copying KB domains..."
cp -r "${SOURCE_DIR}/kb" "${PLUGIN_DIR}/kb"

info "Copying SDD templates and architecture..."
mkdir -p "${PLUGIN_DIR}/sdd"
cp -r "${SOURCE_DIR}/sdd/templates"    "${PLUGIN_DIR}/sdd/templates"
cp -r "${SOURCE_DIR}/sdd/architecture" "${PLUGIN_DIR}/sdd/architecture"

info "Copying manifest..."
cp "${SOURCE_DIR}/manifest.yaml" "${PLUGIN_DIR}/manifest.yaml"

info "Copying hooks..."
cp -r "${SOURCE_DIR}/hooks" "${PLUGIN_DIR}/hooks"

ok "All components copied"

# --- Step 3: Path rewriting --------------------------------------------------
#
# REWRITE (plugin-internal references):
#   .github/kb/                  -> ${COPILOT_PLUGIN_ROOT}/kb/
#   .github/agents/              -> ${COPILOT_PLUGIN_ROOT}/agents/
#   .github/skills/              -> ${COPILOT_PLUGIN_ROOT}/skills/
#   .github/sdd/templates/       -> ${COPILOT_PLUGIN_ROOT}/sdd/templates/
#   .github/sdd/architecture/    -> ${COPILOT_PLUGIN_ROOT}/sdd/architecture/
#
# PRESERVE (workspace output paths -- must NOT be rewritten):
#   .github/sdd/features/        -> stays as-is (user project workspace)
#   .github/sdd/reports/         -> stays as-is (user project workspace)
#   .github/sdd/archive/         -> stays as-is (user project workspace)
#   .github/copilot-instructions.md -> stays as-is (user project)
# -----------------------------------------------------------------------------

info "Rewriting paths in .md, .yaml, and .json files..."

while IFS= read -r -d '' file; do
    tmp="${file}.tmp"
    sed \
        -e 's|\.github/kb/|${COPILOT_PLUGIN_ROOT}/kb/|g' \
        -e 's|\.github/agents/|${COPILOT_PLUGIN_ROOT}/agents/|g' \
        -e 's|\.github/skills/|${COPILOT_PLUGIN_ROOT}/skills/|g' \
        -e 's|\.github/sdd/templates/|${COPILOT_PLUGIN_ROOT}/sdd/templates/|g' \
        -e 's|\.github/sdd/architecture/|${COPILOT_PLUGIN_ROOT}/sdd/architecture/|g' \
        "$file" > "$tmp" && mv "$tmp" "$file" || { rm -f "$tmp"; exit 1; }
done < <(find "${PLUGIN_DIR}" \( -name "*.md" -o -name "*.yaml" -o -name "*.yml" -o -name "*.json" \) \
    -type f -print0)

ok "Paths rewritten"

# --- Step 4: Restore workspace paths (over-rewritten by step 3) --------------
#
# Step 3 rewrites ALL .github/sdd/ references. features/reports/archive are
# workspace output paths that must remain as .github/sdd/<dir>/.
# -----------------------------------------------------------------------------

info "Restoring workspace output paths..."

while IFS= read -r -d '' file; do
    tmp="${file}.tmp"
    sed \
        -e 's|\${COPILOT_PLUGIN_ROOT}/sdd/features/|.github/sdd/features/|g' \
        -e 's|\${COPILOT_PLUGIN_ROOT}/sdd/reports/|.github/sdd/reports/|g' \
        -e 's|\${COPILOT_PLUGIN_ROOT}/sdd/archive/|.github/sdd/archive/|g' \
        "$file" > "$tmp" && mv "$tmp" "$file" || { rm -f "$tmp"; exit 1; }
done < <(find "${PLUGIN_DIR}" -type f -name "*.md" -print0)

ok "Workspace paths restored"

# --- Step 5: Rewrite hardcoded absolute paths --------------------------------

info "Rewriting absolute paths..."
while IFS= read -r -d '' file; do
    tmp="${file}.tmp"
    sed \
        -e 's|/[^ ]*\${COPILOT_PLUGIN_ROOT}/|${COPILOT_PLUGIN_ROOT}/|g' \
        -e 's|/[^ ]*/\.github/skills/|${COPILOT_PLUGIN_ROOT}/skills/|g' \
        -e 's|cd \.github/skills/|cd ${COPILOT_PLUGIN_ROOT}/skills/|g' \
        "$file" > "$tmp" && mv "$tmp" "$file" || { rm -f "$tmp"; exit 1; }
done < <(find "${PLUGIN_DIR}" -type f \( -name "*.md" -o -name "*.sh" \) -print0)

ok "Absolute paths rewritten"

# --- Step 6: Verify no stale .github/ paths remain --------------------------

info "Verifying path migration..."

_stale_filter() {
    grep -r '\.github/' "${PLUGIN_DIR}" \
        --include="*.md" --include="*.yaml" --include="*.yml" \
        | grep -v 'COPILOT_PLUGIN_ROOT' \
        | grep -v '\.github/sdd/features' \
        | grep -v '\.github/sdd/reports' \
        | grep -v '\.github/sdd/archive' \
        | grep -v '\.github/sdd/' \
        | grep -v '\.github/storage' \
        | grep -v '\.github/workflows/' \
        | grep -v '\.github/commands/' \
        | grep -v '\.github/copilot-instructions' \
        | grep -v '\.github/CLAUDE\.md' \
        | grep -v '\.github/\*\*' \
        | grep -v '^[[:space:]]*#' \
        | grep -v '├── \.github' \
        || true
}

STALE_OUTPUT=$(_stale_filter)
STALE_COUNT=$(printf '%s' "${STALE_OUTPUT}" | grep -c '.' || true)

if [[ "${STALE_COUNT}" -gt 0 ]]; then
    warn "${STALE_COUNT} potentially stale .github/ references found:"
    printf '%s\n' "${STALE_OUTPUT}" | head -20
    echo ""
    warn "Review the above -- some may be intentional (workspace paths)."
else
    ok "No stale .github/ paths found"
fi

# --- Step 7: Summary ---------------------------------------------------------

AGENT_COUNT=$(find "${PLUGIN_DIR}/agents" -name "*.agent.md" -type f 2>/dev/null | wc -l | tr -d ' ')
SKILL_COUNT=$(find "${PLUGIN_DIR}/skills" -name "SKILL.md" -type f 2>/dev/null | wc -l | tr -d ' ')
KB_COUNT=$(find "${PLUGIN_DIR}/kb" -maxdepth 1 -type d ! -name "kb" ! -name "_templates" ! -name "shared" 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "============================================"
printf "${GREEN}AgentSpec Copilot CLI Plugin Build Complete${NC}\n"
echo "============================================"
echo "  Agents:   ${AGENT_COUNT}"
echo "  Skills:   ${SKILL_COUNT}"
echo "  KB:       ${KB_COUNT} domains"
echo ""
echo "  Output:   ${PLUGIN_DIR}/"
echo ""
echo "  Distribute as a gh extension:"
echo "    gh extension install ."
echo ""
echo "  Validate with:"
echo "    cat ${PLUGIN_DIR}/manifest.yaml"
echo "============================================"
