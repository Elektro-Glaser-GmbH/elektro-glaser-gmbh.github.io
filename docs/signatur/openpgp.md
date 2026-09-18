# OpenPGP

Zweiter, vom DNS unabhängiger Prüfweg: Ein OpenPGP-Schlüssel der Elektro-Glaser GmbH liegt auf
[keys.openpgp.org](https://keys.openpgp.org). Mit ihm wird die Datei `oeffentliches_zertifikat.pem` signiert.

> **Wichtig:** keys.openpgp.org speichert nur OpenPGP-Schlüssel, **keine X.509-Zertifikate**. Das
> Signaturzertifikat selbst kann dort nicht hochgeladen werden. Die Verbindung entsteht über die
> OpenPGP-Signatur (`.asc`) der Zertifikatsdatei.

## Einmalig: Schlüssel anlegen und veröffentlichen

1. Schlüssel erzeugen (Ed25519, E-Mail-Adresse der Firma als User-ID):

   ```bash
   gpg --quick-generate-key "Elektro-Glaser GmbH <info@e-glaser.de>" ed25519 sign 5y
   gpg --list-keys --keyid-format long "info@e-glaser.de"
   ```

2. Schlüssel hochladen – im Browser unter [keys.openpgp.org/upload](https://keys.openpgp.org/upload) mit der Datei
   aus `gpg --export --armor info@e-glaser.de > elektro-glaser.asc`, oder direkt:

   ```bash
   gpg --export info@e-glaser.de | curl -T - https://keys.openpgp.org
   ```

3. **E-Mail-Adresse bestätigen:** keys.openpgp.org schickt einen Bestätigungslink an `info@e-glaser.de`. Erst
   danach ist der Schlüssel über die E-Mail-Adresse auffindbar.
4. Privaten Schlüssel und Widerrufszertifikat sichern (KeePass):

   ```bash
   gpg --export-secret-keys --armor info@e-glaser.de > elektro-glaser-private.asc
   cp ~/.gnupg/openpgp-revocs.d/<FINGERPRINT>.rev .
   ```

   Beide Dateien danach wie in [README.md](README.md#sicherheitsregeln) beschrieben löschen.
5. In `pages/zertifikat.vue` den Platzhalter ersetzen – den **vollständigen 40-stelligen Fingerprint** verwenden,
   keine kurze Key-ID (kurze IDs lassen sich fälschen):

   ```ts
   const OPENPGP_KEY_ID = 'ABCD1234ABCD1234ABCD1234ABCD1234ABCD1234'
   ```

## Jährlich: Zertifikatsdatei signieren

Nach jedem neuen Signaturzertifikat (siehe [Jahreswechsel](jahreswechsel.md)):

```bash
rm -f public/oeffentliches_zertifikat.pem.asc
gpg --local-user <FINGERPRINT> --armor --detach-sign public/oeffentliches_zertifikat.pem
gpg --verify public/oeffentliches_zertifikat.pem.asc public/oeffentliches_zertifikat.pem
git add public/oeffentliches_zertifikat.pem.asc
```

Sobald `public/oeffentliches_zertifikat.pem.asc` existiert, zeigt die Seite `/zertifikat` automatisch einen
zusätzlichen Download-Button „OpenPGP-Signatur (.asc)“ an.

Optional können auch die Archivdateien signiert werden (`public/zertifikate/*.pem.asc`); die Seite verlinkt diese
derzeit nicht.

## Prüfung durch Dritte

```bash
gpg --keyserver hkps://keys.openpgp.org --recv-keys <FINGERPRINT>
gpg --verify oeffentliches_zertifikat.pem.asc oeffentliches_zertifikat.pem
```

Erwartet: `Korrekte Signatur von "Elektro-Glaser GmbH <info@e-glaser.de>"`.

## Ablauf des PGP-Schlüssels

Der Schlüssel ist oben auf 5 Jahre befristet. Vor Ablauf verlängern und erneut hochladen:

```bash
gpg --quick-set-expire <FINGERPRINT> 5y
gpg --export <FINGERPRINT> | curl -T - https://keys.openpgp.org
```
