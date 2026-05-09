# ── Elektro-Glaser – Makefile ─────────────────────────────────────────────────
# Häufig genutzte Befehle für das Nuxt / GitHub-Pages-Projekt.
#
# Voraussetzungen:
#   - Node.js + npm  (für Nuxt)
#   - uv             (für Python-Skripte, https://docs.astral.sh/uv/)
#
# Verwendung:
#   make              → diese Hilfe anzeigen
#   make dev          → Nuxt-Dev-Server starten
#   make check-links  → vollständige Link-Prüfung (extern + intern)
# ─────────────────────────────────────────────────────────────────────────────

.DEFAULT_GOAL := help
.PHONY: help dev build generate preview install \
        check-links check-links-fast check-links-ci check-links-log \
        check-links-reset restore-assets restore-assets-do

# ── Variablen ─────────────────────────────────────────────────────────────────

LOG      ?= /tmp/links.log
WORKERS  ?= 10
TIMEOUT  ?= 15

# ── Hilfe ─────────────────────────────────────────────────────────────────────

help:
	@echo ""
	@echo "  Elektro-Glaser – verfügbare Targets"
	@echo ""
	@echo "  Nuxt"
	@echo "    make install            npm-Abhängigkeiten installieren"
	@echo "    make dev                Nuxt-Dev-Server starten  (http://localhost:3000)"
	@echo "    make build              SSR-Build"
	@echo "    make generate           Statische Seite generieren (GitHub Pages)"
	@echo "    make preview            Generierten Output lokal betrachten"
	@echo ""
	@echo "  Link-Prüfung"
	@echo "    make check-links        Vollständig: extern + intern (interaktiv)"
	@echo "    make check-links-fast   Nur interne Links, kein HTTP (sehr schnell)"
	@echo "    make check-links-ci     Nicht-interaktiv (für CI-Pipelines)"
	@echo "    make check-links-log    Vollständig + Log nach \$$LOG (Standard: $(LOG))"
	@echo "    make check-links-reset  Link-Cache (.link_cache.json) löschen"
	@echo ""
	@echo "  Assets"
	@echo "    make restore-assets     Dry-Run: fehlende Assets anzeigen"
	@echo "    make restore-assets-do  Fehlende Assets tatsächlich nach public/ kopieren"
	@echo ""

# ── Nuxt ──────────────────────────────────────────────────────────────────────

install:
	npm install

dev:
	npm run dev

build:
	npm run build

generate:
	npm run generate

preview:
	npm run preview

# ── Link-Prüfung ──────────────────────────────────────────────────────────────

check-links:
	uv run --script scripts/check-links.py \
		--workers $(WORKERS) --timeout $(TIMEOUT)

check-links-fast:
	uv run --script scripts/check-links.py --no-external

check-links-ci:
	uv run --script scripts/check-links.py \
		--workers $(WORKERS) --timeout $(TIMEOUT) \
		--non-interactive

check-links-log:
	uv run --script scripts/check-links.py \
		--workers $(WORKERS) --timeout $(TIMEOUT) \
		--log $(LOG)
	@echo ""
	@echo "  Log geschrieben nach $(LOG)"

check-links-reset:
	@rm -f .link_cache.json
	@echo "  Link-Cache gelöscht."

# ── Assets ────────────────────────────────────────────────────────────────────

restore-assets:
	uv run --script scripts/restore-missing-assets.py --dry-run \
		--log $(LOG)

restore-assets-do:
	uv run --script scripts/restore-missing-assets.py \
		--log $(LOG)
