# Dokumentation

Technische Dokumentation zur Website der Elektro-Glaser GmbH. Allgemeine Hinweise zu Entwicklung, Blog und
Deployment stehen in der [README im Projekt-Root](../README.md).

> Dieses Verzeichnis ist reine Entwicklerdokumentation. Es wird **nicht** auf der Website veröffentlicht –
> `@nuxt/content` liest ausschließlich `content/`, und `nuxt generate` übernimmt nur `public/`.

## Inhalt

### Digitale Signatur von Prüfprotokollen (PAdES)

| Dokument | Inhalt |
|---|---|
| [Überblick & Architektur](signatur/README.md) | Konzept, beteiligte Dateien, Sicherheitsregeln |
| [Zertifikat erstellen](signatur/zertifikat-erstellen.md) | Skript-Referenz, Ersteinrichtung, Fehlerbehebung |
| [Jahreswechsel (Runbook)](signatur/jahreswechsel.md) | Checkliste für das jährliche Zertifikat |
| [DNS-Einträge](signatur/dns.md) | TXT-Format, deSEC, DNSSEC, 10-Jahres-Historie |
| [OpenPGP](signatur/openpgp.md) | Schlüssel auf keys.openpgp.org, Signatur der Zertifikatsdatei |
| [Verifikationsseite `/zertifikat`](signatur/verifikationsseite.md) | Aufbau der Seite, Datenfluss, Platzhalter |

## Konventionen

- Sprache der Dokumentation: Deutsch.
- Markdown wird per `markdownlint` geprüft (pre-commit, Konfiguration in `.markdownlint.yaml`, max. 120 Zeichen/Zeile).
- Befehle beziehen sich, wenn nicht anders angegeben, auf das Repository-Root als Arbeitsverzeichnis.
