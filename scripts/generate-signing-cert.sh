#!/usr/bin/env bash
# ── Elektro-Glaser – Signaturzertifikat erzeugen (ein Kalenderjahr) ───────────
# Erzeugt lokal im Ordner tmp/ (git-ignoriert) für genau EIN Kalenderjahr:
#   - einen 4096-Bit-RSA-Schlüssel (passwortgeschützt, AES-256)
#   - ein selbstsigniertes X.509-Zertifikat, gültig bis 31.12. 23:59:59 (dt. Zeit)
#   - eine passwortgeschützte PKCS#12-Datei (.p12) für die Signatursoftware
#   - das öffentliche Zertifikat
# Veröffentlicht NUR das öffentliche Zertifikat:
#   public/oeffentliches_zertifikat.pem                       (immer das aktuelle)
#   public/zertifikate/elektro-glaser-signatur-<JAHR>.pem     (Archiv, alle Jahre)
#   public/zertifikate/index.json                             (Manifest für die Webseite)
#
# Verwendung (aus dem Repo-Root):
#   bash scripts/generate-signing-cert.sh          → Zertifikat für das laufende Jahr (ab sofort)
#   bash scripts/generate-signing-cert.sh 2027     → Zertifikat für 2027 (ab 01.01.2027 00:00)
#   bash scripts/generate-signing-cert.sh --dns    → nur DNS-TXT-Einträge aus dem Manifest ausgeben
#
# Nach Abschluss: .p12 + privaten Schlüssel ins KeePass, danach tmp/ löschen!
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail
umask 077   # alle erzeugten Dateien nur für den eigenen Benutzer lesbar

# ── Konfiguration ─────────────────────────────────────────────────────────────
ORG="Elektro-Glaser GmbH"
COUNTRY="DE"
STATE="Bayern"
CITY="Erlangen"
TZ_LOCAL="Europe/Berlin"          # Jahresgrenze nach deutscher Zeit
KEY_BITS=4096

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$REPO_ROOT/tmp"
PUBLIC_DIR="$REPO_ROOT/public"    # Nuxt: Inhalte werden 1:1 unter / ausgeliefert
ARCHIVE_DIR="$PUBLIC_DIR/zertifikate"
GITIGNORE="$REPO_ROOT/.gitignore"
MANIFEST_JS="$REPO_ROOT/scripts/signing-cert-manifest.mjs"

die() { echo "❌ $*" >&2; exit 1; }

command -v openssl >/dev/null || die "openssl ist nicht installiert."
command -v node    >/dev/null || die "node ist nicht installiert."
[[ -d "$PUBLIC_DIR" ]] || die "Ordner $PUBLIC_DIR nicht gefunden – Skript im Repo ausführen."

if [[ "${1:-}" == "--dns" ]]; then
  node "$MANIFEST_JS" dns
  exit 0
fi

# ── Jahr & Gültigkeitszeitraum bestimmen ──────────────────────────────────────
CURRENT_YEAR="$(TZ="$TZ_LOCAL" date +%Y)"
YEAR="${1:-$CURRENT_YEAR}"
[[ "$YEAR" =~ ^20[0-9]{2}$ ]] || die "Ungültiges Jahr: $YEAR"
(( YEAR >= CURRENT_YEAR )) || die "Zertifikate für vergangene Jahre ($YEAR) werden nicht erzeugt."

# openssl ca erwartet UTCTime (YYMMDDHHMMSSZ)
utc() { date -u -d "TZ=\"$TZ_LOCAL\" $1" +%y%m%d%H%M%SZ; }
END_DATE="$(utc "${YEAR}-12-31 23:59:59")"
if (( YEAR == CURRENT_YEAR )); then
  START_DATE="$(date -u +%y%m%d%H%M%SZ)"          # laufendes Jahr: ab jetzt
else
  START_DATE="$(utc "${YEAR}-01-01 00:00:00")"    # Folgejahr: ab Neujahr
fi

CN="Elektro-Glaser GmbH - Dokumentensignatur ${YEAR}"
KEY_FILE="$TMP_DIR/privater_schluessel_${YEAR}.pem"
CSR_FILE="$TMP_DIR/anforderung_${YEAR}.csr"
CERT_FILE="$TMP_DIR/zertifikat_${YEAR}.pem"
P12_FILE="$TMP_DIR/elektro-glaser-signatur-${YEAR}.p12"
PUB_FILE="$TMP_DIR/oeffentliches_zertifikat_${YEAR}.pem"
ARCHIVE_FILE="$ARCHIVE_DIR/elektro-glaser-signatur-${YEAR}.pem"

[[ -e "$ARCHIVE_FILE" ]] && die "Für ${YEAR} existiert bereits $ARCHIVE_FILE – Abbruch."

# ── 1. tmp/ in .gitignore eintragen – BEVOR irgendein Geheimnis entsteht ──────
if ! grep -qxE '/?tmp/?' "$GITIGNORE" 2>/dev/null; then
  printf '\n# Lokale Zertifikats-Generierung (private Schlüssel!)\n/tmp/\n' >> "$GITIGNORE"
  echo "✅ /tmp/ zur .gitignore hinzugefügt."
fi

mkdir -p "$TMP_DIR"
chmod 700 "$TMP_DIR"

if git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$REPO_ROOT" check-ignore -q "$TMP_DIR/probe" \
    || die "tmp/ wird von git NICHT ignoriert – Abbruch."
  echo "✅ git ignoriert tmp/."
fi

if compgen -G "$TMP_DIR/*" >/dev/null; then
  die "tmp/ ist nicht leer. Alte Dateien sichern/löschen und erneut starten."
fi

echo "📅 Zertifikat für ${YEAR}: gültig von $(date -d "$(sed -E 's/^(..)(..)(..)(..)(..)(..)Z$/20\1-\2-\3 \4:\5:\6 UTC/' <<<"$START_DATE")" '+%d.%m.%Y %H:%M') bis 31.12.${YEAR} 23:59:59 (${TZ_LOCAL})"

# ── 2. Passwort abfragen (nicht in Shell-History / Prozessliste) ──────────────
read -rsp "🔑 Passwort für Schlüssel und .p12 (min. 12 Zeichen): " CERT_PASS; echo
read -rsp "🔑 Passwort wiederholen: " CERT_PASS2; echo
[[ "$CERT_PASS" == "$CERT_PASS2" ]] || die "Passwörter stimmen nicht überein."
(( ${#CERT_PASS} >= 12 )) || die "Passwort zu kurz (min. 12 Zeichen)."
unset CERT_PASS2
export CERT_PASS   # nur über env:CERT_PASS an openssl, nie als Argument
trap 'unset CERT_PASS' EXIT

# ── 3. 4096-Bit-RSA-Schlüssel (AES-256 verschlüsselt) ─────────────────────────
echo "⏳ Erzeuge ${KEY_BITS}-Bit-RSA-Schlüssel …"
openssl genpkey -algorithm RSA -pkeyopt "rsa_keygen_bits:${KEY_BITS}" \
  -aes-256-cbc -pass env:CERT_PASS -out "$KEY_FILE" 2>/dev/null

# ── 4. Selbstsigniertes X.509-Zertifikat für Dokumentensignatur (PAdES) ───────
# `openssl ca -selfsign` statt `req -x509`, weil nur so exakte Start-/Enddaten
# (Kalenderjahr) mit jeder OpenSSL-Version möglich sind.
# EKU: emailProtection + Microsoft Document Signing + id-kp-documentSigning
# (RFC 9336) – damit akzeptieren Adobe Acrobat & Co. das Zertifikat zum Signieren.
CA_DIR="$TMP_DIR/ca"
mkdir -p "$CA_DIR/newcerts"
: > "$CA_DIR/index.txt"
cat > "$CA_DIR/openssl.cnf" <<EOF
[ ca ]
default_ca       = sig_ca

[ sig_ca ]
dir              = $CA_DIR
database         = \$dir/index.txt
new_certs_dir    = \$dir/newcerts
rand_serial      = yes
default_md       = sha256
policy           = policy_sig
unique_subject   = no
preserve         = yes
email_in_dn      = no
copy_extensions  = none
x509_extensions  = sig_ext

[ policy_sig ]
countryName            = supplied
stateOrProvinceName    = optional
localityName           = optional
organizationName       = supplied
commonName             = supplied

[ sig_ext ]
basicConstraints       = critical,CA:FALSE
keyUsage               = critical,digitalSignature,nonRepudiation
extendedKeyUsage       = emailProtection,1.3.6.1.4.1.311.10.3.12,1.3.6.1.5.5.7.3.36
subjectKeyIdentifier   = hash
EOF

echo "⏳ Erzeuge selbstsigniertes Zertifikat für ${YEAR} …"
openssl req -new -utf8 -sha256 \
  -key "$KEY_FILE" -passin env:CERT_PASS \
  -subj "/C=${COUNTRY}/ST=${STATE}/L=${CITY}/O=${ORG}/CN=${CN}" \
  -out "$CSR_FILE"

openssl ca -batch -selfsign -utf8 -notext \
  -config "$CA_DIR/openssl.cnf" \
  -keyfile "$KEY_FILE" -passin env:CERT_PASS \
  -startdate "$START_DATE" -enddate "$END_DATE" \
  -in "$CSR_FILE" -out "$CERT_FILE" 2>/dev/null \
  || die "Signieren des Zertifikats fehlgeschlagen."

# ── 5. PKCS#12 (.p12) mit Passwort ────────────────────────────────────────────
echo "⏳ Exportiere PKCS#12 …"
openssl pkcs12 -export \
  -name "$CN" \
  -inkey "$KEY_FILE" -passin env:CERT_PASS \
  -in "$CERT_FILE" \
  -keypbe AES-256-CBC -certpbe AES-256-CBC -macalg sha256 \
  -passout env:CERT_PASS \
  -out "$P12_FILE"

# ── 6. Öffentliches Zertifikat aus der .p12 extrahieren ───────────────────────
openssl pkcs12 -in "$P12_FILE" -clcerts -nokeys -passin env:CERT_PASS \
  | openssl x509 -out "$PUB_FILE"

# Sicherheitsnetz: niemals etwas Privates veröffentlichen
grep -q "PRIVATE KEY" "$PUB_FILE" && die "Öffentliche Datei enthält einen privaten Schlüssel – Abbruch!"
openssl x509 -in "$PUB_FILE" -noout >/dev/null || die "Öffentliches Zertifikat ungültig."

# ── 7. Veröffentlichen: aktuelles Zertifikat + Jahresarchiv + Manifest ────────
mkdir -p "$ARCHIVE_DIR"
chmod 755 "$ARCHIVE_DIR"
install -m 644 "$PUB_FILE" "$ARCHIVE_FILE"
install -m 644 "$PUB_FILE" "$PUBLIC_DIR/oeffentliches_zertifikat.pem"
node "$MANIFEST_JS" add "$YEAR" "$ARCHIVE_FILE"
chmod 644 "$ARCHIVE_DIR/index.json"
echo "✅ Veröffentlicht: public/oeffentliches_zertifikat.pem"
echo "✅ Archiviert:     public/zertifikate/elektro-glaser-signatur-${YEAR}.pem"
echo "✅ Manifest:       public/zertifikate/index.json"

# ── 8. Zusammenfassung, Fingerprint & DNS ─────────────────────────────────────
FP_COLON="$(openssl x509 -in "$PUB_FILE" -noout -fingerprint -sha256 | cut -d= -f2)"

echo
echo "──────────────────────────────────────────────────────────────────────"
openssl x509 -in "$PUB_FILE" -noout -subject -startdate -enddate -serial
echo "──────────────────────────────────────────────────────────────────────"
echo "SHA256-Fingerprint (Webseite / Acrobat-Anzeige):"
echo "  $FP_COLON"
echo
echo "DNS-TXT-Einträge (vollständiger Soll-Zustand):"
node "$MANIFEST_JS" dns | sed 's/^/  /'
echo "──────────────────────────────────────────────────────────────────────"
echo
echo "Erzeugte Dateien in tmp/:"
ls -l "$TMP_DIR"
echo
echo "⚠️  JETZT: $(basename "$P12_FILE") und $(basename "$KEY_FILE") ins KeePass verschieben,"
echo "    danach tmp/ restlos löschen:  find tmp -type f -exec shred -u {} + && rm -rf tmp"
