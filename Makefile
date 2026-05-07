# Makefile — AgentSpec Copilot CLI contributor tooling

SHELL := /usr/bin/env bash

.DEFAULT_GOAL := help

# Detect OS for cross-platform compat
UNAME := $(shell uname -s 2>/dev/null || echo Windows)

.PHONY: help build check generate lint clean install-deps

## help: Show this help message
help:
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## //' | column -t -s ':'

## build: Build the plugin-copilot/ distribution from .github/
build:
	./build-copilot.sh

## check: Validate manifest, agent count, skill count, KB domain count
check:
	@echo "Checking plugin-copilot/manifest.yaml ..."
	@python3 -c "import yaml, sys; yaml.safe_load(open('plugin-copilot/manifest.yaml'))" \
		&& echo "  manifest.yaml: OK" || (echo "  manifest.yaml: INVALID YAML" && exit 1)
	@agent_count=$$(find plugin-copilot/agents -name '*.agent.md' | wc -l | tr -d ' '); \
		echo "  Agents: $${agent_count}"; \
		if [ "$${agent_count}" -lt 50 ]; then echo "  ERROR: expected >=50 agents" && exit 1; fi
	@skill_count=$$(find plugin-copilot/skills -name 'SKILL.md' | wc -l | tr -d ' '); \
		echo "  Skills: $${skill_count}"; \
		if [ "$${skill_count}" -lt 4 ]; then echo "  ERROR: expected >=4 skills" && exit 1; fi
	@kb_count=$$(find plugin-copilot/kb -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' '); \
		echo "  KB domains: $${kb_count}"; \
		if [ "$${kb_count}" -lt 20 ]; then echo "  ERROR: expected >=20 KB domains" && exit 1; fi
	@echo "check: all validations passed."

## generate: Re-run agent router generation (Step 0 of build)
generate:
	python3 scripts/generate-agent-router.py

## lint: Run shellcheck on shell scripts
lint:
	@if ! command -v shellcheck &>/dev/null; then \
		echo "shellcheck not found. Install with: brew install shellcheck (macOS) or apt-get install shellcheck (Linux)"; \
		exit 1; \
	fi
	shellcheck build-copilot.sh
	shellcheck scripts/init-workspace.sh
	@if [ -f .github/skills/visual-explainer/scripts/share.sh ]; then \
		shellcheck .github/skills/visual-explainer/scripts/share.sh; \
	fi
	@echo "lint: all shellcheck checks passed."

## clean: Remove generated plugin-copilot/ artifacts (preserves .claude-plugin/ and README.md)
clean:
	@if [ -d plugin-copilot ]; then \
		find plugin-copilot/ -mindepth 1 -maxdepth 1 \
			! -name '.claude-plugin' \
			! -name 'README.md' \
			-exec rm -rf {} +; \
		echo "clean: plugin-copilot/ cleaned (preserved .claude-plugin/ and README.md)"; \
	else \
		echo "clean: plugin-copilot/ does not exist, nothing to clean"; \
	fi

## install-deps: Install Python development dependencies
install-deps:
	@if command -v pip3 &>/dev/null; then \
		pip3 install pyyaml --quiet && echo "install-deps: pyyaml installed."; \
	else \
		echo "pip3 not found. Install Python 3 first."; exit 1; \
	fi
	@if ! command -v shellcheck &>/dev/null; then \
		echo ""; \
		echo "Optional: install shellcheck for 'make lint'"; \
		echo "  macOS:  brew install shellcheck"; \
		echo "  Linux:  apt-get install shellcheck"; \
	fi
