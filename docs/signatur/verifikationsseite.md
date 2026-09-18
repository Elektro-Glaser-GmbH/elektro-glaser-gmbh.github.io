# Verifikationsseite `/zertifikat`

Öffentliche Seite, die Laien und Netzbetreibern erklärt, wie sie die Signatur unserer Prüfprotokolle prüfen.
Live: [e-glaser.de/zertifikat](https://e-glaser.de/zertifikat).

## Aufbau

| Abschnitt | Anker | Inhalt |
|---|---|---|
| Zertifikat auf einen Blick | – | aktuelles Jahr, Gültigkeit, Fingerprint, Download, Kopier-Button |
| „Warum nicht vertrauenswürdig?“ | – | Erklärung selbst ausgestellter Zertifikate, Jahresmodell |
| Drei Prüfwege (Kacheln) | – | Sprungmarken zu den drei Abschnitten unten |
| So prüfen Sie ein Protokoll | – | Schritt-für-Schritt für Adobe Acrobat |
| 1. DNS | `#dns` | `dig`/`nslookup`, erwartete Antwort, Jahres-Einträge |
| 2. OpenPGP | `#openpgp` | Key-ID, Link zu keys.openpgp.org, `gpg`-Befehle |
| 3. Git | `#git` | Link zur Historie auf GitHub, `git log`-Befehle |
| Öffentliches Zertifikat | `#zertifikat` | PEM-Text mit Kopier-Button, `openssl`-Befehl |
| Zertifikatsarchiv | `#archiv` | Tabelle aller Jahre mit Gültigkeit, Fingerprint, DNS-Name, Download |

Eingebunden ist die Seite im Footer (`layouts/default.vue`: Spalte „Seiten“ und neben Impressum/Datenschutz) und
im Impressum (`pages/impressum.vue`, Absatz „Digitale Signatur“). In der Hauptnavigation steht sie bewusst nicht,
weil sie sich an Fachpublikum richtet.

## Datenfluss

Alle Zertifikatsdaten werden **zur Build-Zeit** aus `public/` gelesen – die Seite enthält danach alles als
statisches HTML, ohne Laufzeit-Requests:

```text
scripts/generate-signing-cert.sh
        │ schreibt
        ▼
public/zertifikate/index.json ──┐
public/oeffentliches_zertifikat.pem ──┤  import.meta.glob(…, { query: '?raw', eager: true })
public/oeffentliches_zertifikat.pem.asc ──┤  (nur Existenzprüfung)
public/openpgp_schluessel.asc ──┘
        │
        ▼
pages/zertifikat.vue  ──nuxt generate──▶  .output/public/zertifikat/index.html
```

- `import.meta.glob` liefert ein **leeres Objekt**, wenn eine Datei (noch) nicht existiert. Der Build bleibt dadurch
  grün, auch bevor das erste Zertifikat erzeugt wurde.
- Das neueste Jahr in `index.json` gilt als **aktuelles** Zertifikat, alle anderen erscheinen im Archiv.
- Datumsangaben werden in `Europe/Berlin` formatiert, damit `22:59:59Z` als „31.12.“ erscheint.
- DNS-Namen werden im Archiv nur für die letzten 10 Jahre (relativ zum aktuellen Jahr) angezeigt, ältere als
  „nicht mehr im DNS“ – passend zu `scripts/signing-cert-manifest.mjs dns`.

## Platzhalter

Konstanten oben in `pages/zertifikat.vue`:

| Konstante | Quelle | Zu tun |
|---|---|---|
| `OPENPGP_KEY_ID`, `OPENPGP_OWNER`, `OPENPGP_EMAILS_B64` | manuell | gesetzt; bei Änderungen am Schlüssel anpassen |
| `SHA256_PLACEHOLDER` | Fallback | nichts – wird angezeigt, solange `index.json` fehlt |

Nicht ersetzte Platzhalter (Werte, die mit `[` beginnen) werden mit der CSS-Klasse `.placeholder` rot und
gestrichelt hervorgehoben, damit sie vor einem Deployment auffallen.

Weitere Konstanten: `DNS_NAME`, `DNS_HISTORY_YEARS`, `CERT_FILE`, `REPO_URL` – bei Domain- oder Repo-Umzug anpassen
(und dann auch `scripts/signing-cert-manifest.mjs`).

## Styling

Die Seite nutzt die bestehenden Klassen der Website (`section`, `container`, `section-label`, `usp-row`,
`usp-item`, `btn-hero`, `btn-primary`, `btn-outline`, `blog-tag`, `hint`). Seitenspezifische Styles stehen in
`assets/css/main.scss` im Abschnitt **„Signaturprüfung / Zertifikat“** (Präfix `cert-`) und verwenden nur die
vorhandenen Design-Tokens (`$primary`, `$secondary`, `$radius-*`, `$shadow-*`).

## Lokal testen

```bash
npm run dev                          # http://localhost:3000/zertifikat
```

Den statischen Build (so wie auf GitHub Pages) prüfen:

```bash
npm run generate
npx serve .output/public             # dann /zertifikat aufrufen
grep -c "BEGIN CERTIFICATE" .output/public/zertifikat/index.html   # 1 = PEM ist eingebettet
```

Zum Testen ohne echtes Zertifikat kann das Skript in einer Wegwerf-Kopie des Repositories laufen; die dort
erzeugten Dateien aus `public/` vorübergehend ins Projekt kopieren und **vor dem Commit wieder entfernen**.

## Git als Prüfweg

Die Seite verweist auf die Commit-Historie von `public/oeffentliches_zertifikat.pem` auf GitHub. Damit diese
Historie belastbar ist, sollte für `main` in den GitHub-Einstellungen (*Settings → Branches / Rules*)
**Force-Push und Löschen verboten** sein. Ohne diese Regel ließe sich die Historie technisch umschreiben – die
Seite spricht deshalb bewusst von „öffentlich nachvollziehbar“ und nicht von „unveränderbar“.
