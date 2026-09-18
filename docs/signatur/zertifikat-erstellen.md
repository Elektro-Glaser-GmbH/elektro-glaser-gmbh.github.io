# Zertifikat erstellen

Referenz für `scripts/generate-signing-cert.sh`. Für den jährlichen Ablauf siehe
[Jahreswechsel (Runbook)](jahreswechsel.md).

## Voraussetzungen

| Werkzeug | Zweck | Hinweis |
|---|---|---|
| `bash`, GNU `date` | Skript, Datumsberechnung | Linux; unter macOS `coreutils` (`gdate`) nötig |
| `openssl` ≥ 1.1.1 | Schlüssel, Zertifikat, PKCS#12 | getestet mit OpenSSL 3.0.13 |
| `node` | Manifest pflegen, DNS-Einträge ausgeben | ist für Nuxt ohnehin installiert |
| `git` | Prüfung, dass `tmp/` ignoriert wird | |

## Aufruf

```bash
bash scripts/generate-signing-cert.sh          # Zertifikat für das laufende Jahr, gültig ab sofort
bash scripts/generate-signing-cert.sh 2027     # Zertifikat für 2027, gültig ab 01.01.2027 00:00
bash scripts/generate-signing-cert.sh --dns    # nur die DNS-TXT-Einträge aus dem Manifest ausgeben
```

| Argument | Wirkung |
|---|---|
| *(keins)* | laufendes Jahr, `notBefore` = jetzt |
| `JAHR` (größer als das laufende Jahr) | `notBefore` = 01.01. 00:00:00 des Jahres (deutsche Zeit) |
| `--dns` | erzeugt nichts, gibt den Soll-Zustand der DNS-Einträge aus |

`notAfter` ist immer der 31.12. 23:59:59 deutscher Zeit (`22:59:59Z`).

Das Skript **bricht ab**, wenn

- das Jahr in der Vergangenheit liegt,
- für das Jahr bereits `public/zertifikate/elektro-glaser-signatur-<JAHR>.pem` existiert,
- `tmp/` nicht leer ist,
- `tmp/` nicht von git ignoriert wird,
- das Passwort kürzer als 12 Zeichen ist oder die Wiederholung abweicht.

## Ablauf im Detail

1. **`.gitignore` absichern:** `/tmp/` wird eingetragen, falls noch nicht vorhanden. Danach wird mit
   `git check-ignore` geprüft, dass Git den Ordner tatsächlich ignoriert – erst dann entsteht ein Geheimnis.
2. **Passwort** verdeckt abfragen (zweimal). Es schützt sowohl den privaten Schlüssel als auch die `.p12`.
3. **Schlüssel:** `openssl genpkey`, RSA 4096, verschlüsselt mit AES-256-CBC.
4. **Zertifikat:** CSR mit `openssl req -new`, danach Selbstsignatur mit `openssl ca -selfsign` und exakten
   `-startdate`/`-enddate`. Die dafür nötige Mini-CA-Konfiguration liegt temporär in `tmp/ca/`.
5. **PKCS#12:** `openssl pkcs12 -export` mit AES-256-CBC und SHA-256-MAC, Anzeigename = CN.
6. **Öffentliches Zertifikat** wird aus der `.p12` extrahiert (nicht aus der Zwischendatei) und auf
   `PRIVATE KEY`-Blöcke geprüft.
7. **Veröffentlichen:**
   - `public/zertifikate/elektro-glaser-signatur-<JAHR>.pem` (Archiv)
   - `public/oeffentliches_zertifikat.pem` (aktuelles Zertifikat, wird überschrieben)
   - Eintrag in `public/zertifikate/index.json` über `scripts/signing-cert-manifest.mjs add`
8. **Ausgabe:** Subject, Gültigkeit, Seriennummer, SHA256-Fingerprint und der komplette Satz DNS-Einträge.

### Warum `openssl ca -selfsign` statt `openssl req -x509`?

`req -x509` kennt nur `-days`; exakte Start- und Endzeitpunkte (`-not_before`/`-not_after`) gibt es erst ab
OpenSSL 3.4. `openssl ca -selfsign` unterstützt `-startdate`/`-enddate` in allen relevanten Versionen und erlaubt
damit Zertifikate, die genau zum Jahreswechsel beginnen und enden.

## Erzeugte Dateien

### Lokal in `tmp/` (geheim → KeePass, danach löschen)

| Datei | Inhalt | Aufbewahren? |
|---|---|---|
| `elektro-glaser-signatur-<JAHR>.p12` | Schlüssel + Zertifikat für die Signatursoftware | **ja, KeePass** |
| `privater_schluessel_<JAHR>.pem` | privater Schlüssel (AES-256-verschlüsselt) | **ja, KeePass** |
| `zertifikat_<JAHR>.pem` | Zertifikat (identisch mit der öffentlichen Datei) | nein |
| `oeffentliches_zertifikat_<JAHR>.pem` | öffentliches Zertifikat | nein (liegt in `public/`) |
| `anforderung_<JAHR>.csr` | Zertifikatsanforderung | nein |
| `ca/` | temporäre OpenSSL-CA-Konfiguration und -Datenbank | nein |

Das Passwort gehört in denselben KeePass-Eintrag.

### Im Repository (öffentlich → committen)

| Datei | Inhalt |
|---|---|
| `public/oeffentliches_zertifikat.pem` | aktuelles Zertifikat |
| `public/zertifikate/elektro-glaser-signatur-<JAHR>.pem` | Archivkopie |
| `public/zertifikate/index.json` | Manifest, Grundlage für Webseite und DNS-Ausgabe |

## Manifest `public/zertifikate/index.json`

Wird ausschließlich von `scripts/signing-cert-manifest.mjs` geschrieben, neuestes Jahr zuerst. Die Werte werden
mit `node:crypto` direkt aus der PEM-Datei gelesen, nicht aus der Skript-Ausgabe.

```json
{
  "certificates": [
    {
      "year": 2027,
      "file": "zertifikate/elektro-glaser-signatur-2027.pem",
      "subject": "C=DE, ST=Bayern, L=Erlangen, O=Elektro-Glaser GmbH, CN=Elektro-Glaser GmbH - Dokumentensignatur 2027",
      "serial": "30285A218E881E709691568D4CABCA3E6D95406E",
      "notBefore": "2026-12-31T23:00:00.000Z",
      "notAfter": "2027-12-31T22:59:59.000Z",
      "sha256": "5B:B1:59:…:33:0E"
    }
  ]
}
```

Das Hilfsskript ist auch direkt nutzbar:

```bash
node scripts/signing-cert-manifest.mjs add 2027 public/zertifikate/elektro-glaser-signatur-2027.pem
node scripts/signing-cert-manifest.mjs dns
```

## Zertifikat in der Signatursoftware verwenden

1. `.p12` aus KeePass exportieren (nur temporär, danach wieder löschen).
2. In der Signatursoftware als digitale ID importieren – in Adobe Acrobat:
   *Einstellungen → Unterschriften → Identitäten und vertrauenswürdige Zertifikate → Digitale IDs → ID hinzufügen*.
3. **Zeitstempel einrichten** (dringend empfohlen): In Acrobat unter
   *Einstellungen → Unterschriften → Zeitstempel für Dokumente* einen Zeitstempeldienst (TSA) hinterlegen.
   Mit Zeitstempel (PAdES-B-T) bleibt nachweisbar, dass ein Protokoll **innerhalb** der Gültigkeit signiert wurde –
   auch nachdem das Zertifikat am 31.12. abgelaufen ist. Ohne Zeitstempel stützt sich die Prüfung nur auf die
   vom Unterzeichner selbst angegebene Signaturzeit.
4. Das alte Jahres-Zertifikat ab dem 01.01. nicht mehr zum Signieren verwenden.

## Eigene Prüfung

```bash
# Details und Gültigkeit
openssl x509 -in public/oeffentliches_zertifikat.pem -noout -subject -dates -serial -ext keyUsage,extendedKeyUsage

# Fingerprint (muss zu index.json, DNS und Webseite passen)
openssl x509 -in public/oeffentliches_zertifikat.pem -noout -fingerprint -sha256

# .p12 prüfen (fragt nach dem Passwort)
openssl pkcs12 -in elektro-glaser-signatur-2027.p12 -info -noout
```

## Fehlerbehebung

- **`tmp/ ist nicht leer`** – Reste eines früheren Laufs. Prüfen, ob `.p12` und Schlüssel bereits im KeePass
  sind, dann `tmp/` löschen.
- **`Für <JAHR> existiert bereits …`** – Für das Jahr gibt es schon ein Zertifikat. Neu ausstellen nur bewusst:
  Archivdatei **und** Eintrag in `index.json` entfernen (siehe unten).
- **`Zertifikate für vergangene Jahre … werden nicht erzeugt`** – Rückdatieren ist nicht vorgesehen.
- **`tmp/ wird von git NICHT ignoriert`** – `.gitignore` wurde verändert oder enthält eine Negativregel
  (`!tmp`). Korrigieren.
- **`Signieren des Zertifikats fehlgeschlagen`** – meist falsches Passwort oder ungültiges Datum. Den
  `openssl ca`-Befehl aus dem Skript ohne `2>/dev/null` ausführen, um die eigentliche Meldung zu sehen.
- **`date: ungültiges Datum`** (macOS) – BSD-`date` kennt `-d` nicht: `brew install coreutils` oder unter
  Linux ausführen.

### Ein Zertifikat ersetzen (z. B. bei Kompromittierung)

Ein kompromittiertes Zertifikat **nicht stillschweigend austauschen** – die Git-Historie macht jede Änderung
sichtbar, und das ist gewollt.

1. Betroffene Auftraggeber/Netzbetreiber informieren.
2. Auf der Seite `/zertifikat` einen Hinweis ergänzen, ab wann das Zertifikat nicht mehr vertrauenswürdig ist.
3. Eintrag für das Jahr aus `public/zertifikate/index.json` entfernen, Archivdatei umbenennen
   (z. B. `…-2027-widerrufen.pem`) und das Skript für das Jahr erneut ausführen.
4. DNS-Einträge (`_signatur` und `<JAHR>._signatur`) aktualisieren, `.asc` neu signieren.
5. Änderung mit aussagekräftiger Commit-Nachricht committen.
