# Elektro-Glaser Website

Offizielle Website der [Elektro-Glaser GmbH](https://www.e-glaser.de) – gebaut mit [Nuxt 3](https://nuxt.com) und [Nuxt Content](https://content.nuxt.com).

[![Build & Deploy](https://github.com/Elektro-Glaser-GmbH/e-glaser.de/actions/workflows/publish.yml/badge.svg)](https://github.com/Elektro-Glaser-GmbH/e-glaser.de/actions/workflows/publish.yml)
[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/Elektro-Glaser-GmbH/e-glaser.de)

## Tech-Stack

| Technologie | Version |
|---|---|
| Nuxt | 3.x |
| @nuxt/content | 2.x |
| Sass | 1.x |
| Node.js (CI) | 22 |

## Entwicklung

```bash
npm install
npm run dev
```

Der Dev-Server läuft unter `http://localhost:3000`.

## Blog-Posts

Blog-Beiträge werden als Markdown-Dateien in `content/blog/` gepflegt:

```text
content/blog/mein-post.md
```

Frontmatter-Schema:

```yaml
---
title: "Titel des Beitrags"
description: "Kurze Beschreibung"
date: 2026-04-26
categories: ["Kategorie1", "Kategorie2"]
author: "Name"
---
```

> **Wichtig:** Das Datumsfeld muss ohne Anführungszeichen angegeben werden, damit die Sortierung korrekt funktioniert.

## Build & Deployment

Die Seite wird über GitHub Actions als statische Site generiert und auf GitHub Pages deployed:

```bash
npm run generate   # Erzeugt .output/public/
```

Jeder Push auf `main` löst automatisch einen Build und Deployment aus. Dabei wird die Versionsnummer per
[paulhatch/semantic-version](https://github.com/paulhatch/semantic-version) ermittelt und als Git-Tag gesetzt:

- Commit-Nachricht enthält `(MAJOR)` → Major-Bump
- Commit-Nachricht enthält `(MINOR)` → Minor-Bump
- Alle anderen Commits → Patch-Bump

## Secrets

| Secret | Beschreibung |
|---|---|
| `STATIC_FORMS_KEY` | API-Key für [StaticForms](https://www.staticforms.dev) (Kontaktformular) |
