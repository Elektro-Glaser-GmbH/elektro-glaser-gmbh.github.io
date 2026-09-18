# Digitale Signatur – Überblick & Architektur

Die Elektro-Glaser GmbH versiegelt Prüfprotokolle (z. B. nach DIN VDE 0100-600 / DIN VDE 0105-100) mit einer
digitalen Signatur nach **PAdES** (PDF Advanced Electronic Signatures). Jede nachträgliche Änderung am PDF macht
die Signatur ungültig.

Das Signaturzertifikat ist **selbst ausgestellt**. PDF-Programme kennen es daher nicht von sich aus und melden
„Identität des Unterzeichners unbekannt“. Die Vertrauenswürdigkeit wird stattdessen über den **SHA256-Fingerprint**
des Zertifikats hergestellt, der an drei voneinander unabhängigen Stellen veröffentlicht ist:

| Quelle | Wer kann sie ändern? | Details |
|---|---|---|
| DNS (`_signatur.e-glaser.de`, DNSSEC-signiert) | nur der Domaininhaber (deSEC-Account) | [dns.md](dns.md) |
| OpenPGP-Keyserver (keys.openpgp.org) | nur der Besitzer des PGP-Schlüssels | [openpgp.md](openpgp.md) |
| Git-Historie dieses Repositories | nur Schreibberechtigte, jede Änderung bleibt sichtbar | [verifikationsseite.md](verifikationsseite.md) |

Die öffentliche Seite [`/zertifikat`](https://e-glaser.de/zertifikat) erklärt Laien und Netzbetreibern alle drei
Prüfwege und bietet das Zertifikat zum Download an.

## Zertifikatsmodell: ein Zertifikat pro Kalenderjahr

- Für **jedes Kalenderjahr** wird ein **neuer Schlüssel** und ein **neues Zertifikat** erzeugt.
- Gültigkeit: vom 01.01. 00:00:00 bis 31.12. 23:59:59 **deutscher Zeit** (`Europe/Berlin`). Wird das Zertifikat
  im laufenden Jahr erzeugt (Ersteinrichtung), beginnt es zum Erzeugungszeitpunkt.
- Für ein Protokoll maßgeblich ist das Zertifikat des Jahres, in dem es signiert wurde.
- Alte Zertifikate werden **nie gelöscht**, sondern im Archiv (`public/zertifikate/`) und auf der Seite weiter
  angeboten. Im DNS bleiben die Jahres-Einträge **10 Jahre** stehen.

Eckdaten jedes Zertifikats:

| Eigenschaft | Wert |
|---|---|
| Schlüssel | RSA 4096 Bit |
| Signaturalgorithmus | SHA-256 mit RSA |
| Subject | `C=DE, ST=Bayern, L=Erlangen, O=Elektro-Glaser GmbH, CN=Elektro-Glaser GmbH - Dokumentensignatur <JAHR>` |
| Key Usage (kritisch) | `digitalSignature`, `nonRepudiation` |
| Extended Key Usage | `emailProtection`, MS Document Signing, `id-kp-documentSigning` (RFC 9336) |
| Basic Constraints (kritisch) | `CA:FALSE` |

Die EKU-Kombination sorgt dafür, dass Adobe Acrobat und andere PAdES-Programme das Zertifikat zum Signieren
von Dokumenten akzeptieren.

## Beteiligte Dateien

```text
scripts/
├── generate-signing-cert.sh        Erzeugt Schlüssel, Zertifikat, .p12 und veröffentlicht das Zertifikat
└── signing-cert-manifest.mjs       Pflegt public/zertifikate/index.json, gibt DNS-Einträge aus
public/
├── oeffentliches_zertifikat.pem    Immer das aktuelle Zertifikat (Download auf der Seite)
├── oeffentliches_zertifikat.pem.asc  OpenPGP-Signatur der PEM-Datei
├── openpgp_schluessel.asc          Öffentlicher OpenPGP-Schlüssel (primär: daniel@e-glaser.de)
└── zertifikate/
    ├── elektro-glaser-signatur-<JAHR>.pem   Archiv, eine Datei pro Jahr
    └── index.json                           Manifest (Jahr, Gültigkeit, Fingerprint, Seriennummer)
pages/zertifikat.vue                Verifikationsseite /zertifikat
assets/css/main.scss                Abschnitt „Signaturprüfung / Zertifikat“
layouts/default.vue                 Footer-Links auf /zertifikat
tmp/                                NUR LOKAL, git-ignoriert: private Schlüssel und .p12
```

## Sicherheitsregeln

1. **Private Schlüssel und `.p12`-Dateien gelangen nie ins Repository.**
   - `tmp/` steht in der `.gitignore`; das Skript prüft das per `git check-ignore`, bevor es etwas erzeugt.
   - Das Skript veröffentlicht nur Dateien, die nachweislich keinen `PRIVATE KEY`-Block enthalten.
   - Zusätzlich schlägt der `gitleaks`-Hook aus `.pre-commit-config.yaml` bei privaten Schlüsseln an.
2. **Aufbewahrung ausschließlich in KeePass:** `.p12`, `privater_schluessel_<JAHR>.pem` und das Passwort.
3. **`tmp/` wird nach jedem Lauf restlos gelöscht:**

   ```bash
   find tmp -type f -exec shred -u {} + && rm -rf tmp
   ```

4. Das Passwort wird verdeckt abgefragt und nur per Umgebungsvariable (`env:CERT_PASS`) an OpenSSL übergeben –
   es erscheint weder in der Shell-History noch in der Prozessliste.
5. Alle erzeugten Dateien in `tmp/` sind nur für den eigenen Benutzer lesbar (`umask 077`, `chmod 700`).

## Weiterführend

- [Zertifikat erstellen](zertifikat-erstellen.md)
- [Jahreswechsel (Runbook)](jahreswechsel.md)
