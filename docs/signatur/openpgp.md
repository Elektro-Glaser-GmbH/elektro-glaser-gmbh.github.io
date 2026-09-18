# OpenPGP

Zweiter, vom DNS unabhängiger Prüfweg: Der OpenPGP-Schlüssel des Geschäftsführers Daniel Glaser liegt auf
[keys.openpgp.org](https://keys.openpgp.org). Mit ihm wird die Datei `oeffentliches_zertifikat.pem` signiert.

> **Wichtig:** keys.openpgp.org speichert nur OpenPGP-Schlüssel, **keine X.509-Zertifikate**. Das
> Signaturzertifikat selbst kann dort nicht hochgeladen werden. Die Verbindung entsteht über die
> OpenPGP-Signatur (`.asc`) der Zertifikatsdatei.

## Verwendeter Schlüssel

| Eigenschaft | Wert |
|---|---|
| Fingerprint | `214A F7FD 2FC8 A6AF 3E54  3C00 88B8 848C E9C1 9294` |
| Algorithmus | Ed25519 (Signieren), Cv25519-Unterschlüssel (Verschlüsseln) |
| User-ID auf der Website | `Daniel Gerold Glaser <daniel@e-glaser.de>` |
| Erstellt / gültig bis | 28.01.2025 / **29.01.2028** |
| Keyserver | [keys.openpgp.org](https://keys.openpgp.org/search?q=214AF7FD2FC8A6AF3E543C0088B8848CE9C19294), `daniel@e-glaser.de` bestätigt |
| Privater Schlüssel | im lokalen gpg-agent, Freigabe per Passphrase (pinentry) |

Auf dem Keyserver sind weitere bestätigte User-IDs am Schlüssel. Wer ihn dort abruft, sieht die dort primäre
User-ID (derzeit `daniel.glaser@energiewende-erhlangen.de`) als Unterzeichner. Die Website bietet deshalb zusätzlich
einen minimalen Export nur mit der Firmenadresse an:

```bash
gpg --armor --export-options export-minimal --export 214AF7FD2FC8A6AF3E543C0088B8848CE9C19294 \
  > public/openpgp_schluessel.asc
```

Den Export nach jeder Änderung am Schlüssel (Verlängerung, neue User-ID) wiederholen und committen. In
`pages/zertifikat.vue` stehen `OPENPGP_KEY_ID` (Fingerprint ohne Leerzeichen) und `OPENPGP_UID`.

### Schlüssel ersetzen

Nur falls der Schlüssel einmal ersetzt werden muss: neuen Schlüssel erzeugen, hochladen, E-Mail bestätigen,
exportieren und die Konstanten anpassen.

```bash
gpg --quick-generate-key "Daniel Gerold Glaser <daniel@e-glaser.de>" ed25519 sign 3y
gpg --export <FINGERPRINT> | curl -T - https://keys.openpgp.org      # Bestätigungsmail an die Adresse
```

Das Widerrufszertifikat (`~/.gnupg/openpgp-revocs.d/<FINGERPRINT>.rev`) gehört ins KeePass.

## Jährlich: Zertifikatsdatei signieren

Nach jedem neuen Signaturzertifikat (siehe [Jahreswechsel](jahreswechsel.md)):

```bash
rm -f public/oeffentliches_zertifikat.pem.asc
gpg --local-user 214AF7FD2FC8A6AF3E543C0088B8848CE9C19294 --armor --detach-sign public/oeffentliches_zertifikat.pem
gpg --verify public/oeffentliches_zertifikat.pem.asc public/oeffentliches_zertifikat.pem
git add public/oeffentliches_zertifikat.pem.asc
```

Sobald `public/oeffentliches_zertifikat.pem.asc` existiert, zeigt die Seite `/zertifikat` automatisch einen
zusätzlichen Download-Button „OpenPGP-Signatur (.asc)“ an.

Optional können auch die Archivdateien signiert werden (`public/zertifikate/*.pem.asc`); die Seite verlinkt diese
derzeit nicht.

## Prüfung durch Dritte

```bash
gpg --keyserver hkps://keys.openpgp.org --recv-keys 214AF7FD2FC8A6AF3E543C0088B8848CE9C19294
# oder: gpg --import openpgp_schluessel.asc   (Datei von der Website)
gpg --verify oeffentliches_zertifikat.pem.asc oeffentliches_zertifikat.pem
```

Erwartet: `Korrekte Signatur von "…"` mit Fingerprint `214A F7FD … E9C1 9294`. Angezeigt wird die primäre User-ID
des importierten Schlüssels – beim Website-Export `daniel@e-glaser.de`, vom Keyserver ggf. eine andere Adresse.

## Ablauf des PGP-Schlüssels

Der Schlüssel läuft am **29.01.2028** ab. Rechtzeitig vorher verlängern, erneut hochladen und den Export auf der
Website aktualisieren:

```bash
FPR=214AF7FD2FC8A6AF3E543C0088B8848CE9C19294
gpg --quick-set-expire $FPR 3y            # Primärschlüssel
gpg --quick-set-expire $FPR 3y '*'        # Unterschlüssel
gpg --export $FPR | curl -T - https://keys.openpgp.org
gpg --armor --export-options export-minimal --export $FPR > public/openpgp_schluessel.asc
```
