# Jahreswechsel (Runbook)

Checkliste für das jährliche Signaturzertifikat. Beispiel: Wechsel von 2026 auf **2027**.

## Mitte Dezember: neues Zertifikat vorbereiten

- [ ] Repository aktualisieren: `git pull`
- [ ] Zertifikat für das Folgejahr erzeugen:

  ```bash
  bash scripts/generate-signing-cert.sh 2027
  ```

- [ ] Skript-Ausgabe prüfen: Gültigkeit `01.01.2027 00:00` bis `31.12.2027 23:59:59`, Fingerprint notieren.
- [ ] Neuen KeePass-Eintrag „Signaturzertifikat 2027“ anlegen mit:
  - `tmp/elektro-glaser-signatur-2027.p12` (Anhang)
  - `tmp/privater_schluessel_2027.pem` (Anhang)
  - Passwort
  - SHA256-Fingerprint (Notiz)
- [ ] `tmp/` restlos löschen:

  ```bash
  find tmp -type f -exec shred -u {} + && rm -rf tmp
  ```

- [ ] Änderungen **noch nicht committen** – sonst zeigt die Website schon im Dezember das Zertifikat für 2027 als
  aktuell an. Alternativ auf einem Branch committen und den Merge für den 01.01. vormerken.

> Das Zertifikat für 2027 ist technisch erst ab 01.01.2027 gültig. Signaturen damit vor Neujahr würden von
> PDF-Programmen als ungültig gemeldet.

## Ab 01.01.: veröffentlichen

- [ ] Änderungen committen und pushen (löst Build & Deployment aus):

  ```bash
  git add public/oeffentliches_zertifikat.pem public/zertifikate/
  git commit -m "feat(signatur): Signaturzertifikat 2027"
  git push
  ```

- [ ] DNS-Einträge per deSEC-API setzen – Token aus `secret/desec-sig`, Befehl siehe
  [dns.md → API](dns.md#api). Soll-Zustand zum Abgleich:

  ```bash
  bash scripts/generate-signing-cert.sh --dns
  ```

  - `_signatur` → Fingerprint 2027
  - `2027._signatur` neu anlegen
  - Einträge, die das Skript unter „können gelöscht werden“ auflistet, entfernen
- [ ] OpenPGP-Signatur der Zertifikatsdatei erneuern (siehe [openpgp.md](openpgp.md)) und committen.
- [ ] Signatursoftware: neue `.p12` als digitale ID importieren, alte ID für neue Signaturen deaktivieren.
  Temporär exportierte `.p12` danach wieder löschen.

## Kontrolle nach dem Deployment

- [ ] `https://e-glaser.de/zertifikat` zeigt „Dokumentensignatur 2027“, Gültigkeit 01.01.2027 – 31.12.2027.
- [ ] Im Archiv steht 2026 weiterhin mit Download.
- [ ] Fingerprints stimmen überall überein:

  ```bash
  curl -s https://e-glaser.de/oeffentliches_zertifikat.pem | openssl x509 -noout -fingerprint -sha256
  dig +short TXT _signatur.e-glaser.de
  dig +short TXT 2027._signatur.e-glaser.de
  dig +short TXT 2026._signatur.e-glaser.de
  ```

- [ ] Ein Testdokument signieren und in Acrobat prüfen: Signatur gültig, Fingerprint = 2027, Zeitstempel vorhanden.

## Kalender

Empfehlung: zwei wiederkehrende Termine anlegen – ca. **15.12.** „Signaturzertifikat Folgejahr erzeugen“ und
**02.01.** „Signaturzertifikat veröffentlichen + DNS“.
