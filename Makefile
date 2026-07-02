.PHONY: help setup hooks install smoke-test status plugins

help: ## Show all available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-16s\033[0m %s\n", $$1, $$2}'

setup: hooks ## First-time setup: enable git hook + create .env + smoke test
	@test -f .env || (cp .env.example .env && echo "-> created .env from .env.example (please fill in)")
	@$(MAKE) smoke-test

hooks: ## Enable git hook (protects main from direct commits)
	git config core.hooksPath .githooks
	@echo "-> core.hooksPath=.githooks set"

install: ## Python environment (optional, for python/notebook skills)
	python3 -m venv .venv
	.venv/bin/pip install -r requirements.txt

smoke-test: ## Check framework setup
	@bash setup/executions/smoke_test.sh

plugins: ## Guide: set up plugins/marketplaces
	@echo "See setup/plugins/plugin_setup.md — register marketplaces, then /plugin install"

status: ## Quick project status (branch, changes, latest tag)
	@echo "=== Git ===" && git branch --show-current && git status --short
	@echo "=== Latest Tag ===" && git describe --tags --abbrev=0 2>/dev/null || echo "(no tag)"
