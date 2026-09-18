# DNS-Einträge

Der SHA256-Fingerprint der Signaturzertifikate wird als TXT-Eintrag unter der Domain `e-glaser.de` veröffentlicht.
Nameserver: **deSEC** (`ns1.desec.io`, `ns2.desec.org`).

## Einträge

| Name | Inhalt | Lebensdauer |
|---|---|---|
| `_signatur.e-glaser.de` | Fingerprint des **aktuellen** Zertifikats | wird jährlich überschrieben |
| `<JAHR>._signatur.e-glaser.de` | Fingerprint des Zertifikats für `<JAHR>` | 10 Jahre, danach löschen |

Beispiel (Stand 2027):

```text
_signatur.e-glaser.de.       3600 IN TXT "v=sig1; y=2027; alg=sha256; fp=5bb1599e1c93b743de136fd5a1bf221783d5a034937adcd481078bf262ac330e"
2027._signatur.e-glaser.de.  3600 IN TXT "v=sig1; y=2027; alg=sha256; fp=5bb1599e1c93b743de136fd5a1bf221783d5a034937adcd481078bf262ac330e"
2026._signatur.e-glaser.de.  3600 IN TXT "v=sig1; y=2026; alg=sha256; fp=4032a27c03f74ee6155d0d8dd84917aac08d0f7a1dd74648d0d4e0cce1a26830"
```

Den vollständigen Soll-Zustand erzeugt immer das Skript aus dem Manifest – Werte nie von Hand abtippen:

```bash
bash scripts/generate-signing-cert.sh --dns
```

## Format des TXT-Werts

```text
v=sig1; y=<JAHR>; alg=sha256; fp=<64 Hex-Zeichen, klein, ohne Doppelpunkte>
```

| Feld | Bedeutung |
|---|---|
| `v=sig1` | Formatversion (eigene Konvention der Elektro-Glaser GmbH) |
| `y` | Kalenderjahr, für das das Zertifikat gilt |
| `alg` | Hash-Algorithmus des Fingerprints |
| `fp` | SHA-256 über das DER-kodierte Zertifikat |

Der Wert `fp` entspricht dem Fingerprint aus `openssl x509 -fingerprint -sha256` bzw. dem „SHA2-256-Fingerabdruck“
in Adobe Acrobat – nur ohne Doppelpunkte und in Kleinbuchstaben.

## Einträge bei deSEC pflegen

### Web-Oberfläche

Unter [desec.io](https://desec.io) → Domain `e-glaser.de` → Record Set hinzufügen/bearbeiten:

| Feld | Wert |
|---|---|
| Type | `TXT` |
| Subname | `_signatur` bzw. `2027._signatur` |
| TTL | `3600` (deSEC-Minimum) |
| Content | `"v=sig1; y=2027; alg=sha256; fp=…"` – **mit** Anführungszeichen |

### API

Alle Änderungen eines Jahreswechsels in einem Aufruf (atomar). Das Token liegt nicht im Repository, sondern im
Passwortmanager.

```bash
export DESEC_TOKEN=…   # deSEC-API-Token, nur für diese Shell
curl -sS -X PATCH https://desec.io/api/v1/domains/e-glaser.de/rrsets/ \
  -H "Authorization: Token $DESEC_TOKEN" \
  -H "Content-Type: application/json" \
  --data @- <<'EOF'
[
  {"subname": "_signatur",      "type": "TXT", "ttl": 3600,
   "records": ["\"v=sig1; y=2027; alg=sha256; fp=<HEX_2027>\""]},
  {"subname": "2027._signatur", "type": "TXT", "ttl": 3600,
   "records": ["\"v=sig1; y=2027; alg=sha256; fp=<HEX_2027>\""]},
  {"subname": "2017._signatur", "type": "TXT", "records": []}
]
EOF
```

Ein RRset mit `"records": []` wird gelöscht.

## Prüfen

```bash
dig +short TXT _signatur.e-glaser.de
dig +short TXT 2026._signatur.e-glaser.de
dig +dnssec TXT _signatur.e-glaser.de @1.1.1.1 | grep flags:   # "ad" = DNSSEC-validiert
```

Windows: `nslookup -type=TXT _signatur.e-glaser.de`. Ohne Terminal:
[Google Admin Toolbox Dig](https://toolbox.googleapps.com/apps/dig/#TXT/_signatur.e-glaser.de).

## DNSSEC

Der DNS-Prüfweg ist nur so stark wie die Absicherung der Antwort. Die Zone `e-glaser.de` ist deshalb per DNSSEC
signiert; ohne DNSSEC könnte ein Angreifer im Netzwerk eine gefälschte TXT-Antwort unterschieben.

Stand 18.09.2026 – Vertrauenskette `.de` → `e-glaser.de` ist **geschlossen**:

| Teil | Wo | Wert |
|---|---|---|
| Zonensignatur | deSEC (automatisch) | `DNSKEY`, Algorithmus 13 (ECDSA P-256/SHA-256) |
| DS-Eintrag | DENIC (über den Registrar) | Key-Tag `23457`, Algorithmus `13`, Digest-Typ `2` (SHA-256) |

Kontrolle:

```bash
dig +short DS e-glaser.de @a.nic.de                              # DS direkt bei DENIC
dig +dnssec SOA e-glaser.de @1.1.1.1 | grep flags:               # "ad" = validiert
dig +dnssec TXT _signatur.e-glaser.de @1.1.1.1 | grep flags:
```

> **Stolperfalle:** Lokale Stub-Resolver wie `systemd-resolved` (`127.0.0.53`) liefern `DS`-Einträge teils nicht
> oder ohne `ad`-Flag aus. Für Prüfungen immer einen validierenden Resolver (z. B. `@1.1.1.1`, `@9.9.9.9`) oder
> direkt `@a.nic.de` angeben.

Bei einem Schlüsseltausch (KSK-Rollover) bei deSEC muss der DS-Eintrag beim Registrar aktualisiert werden, sonst
schlagen **alle** Abfragen der Domain fehl – nicht nur die Signatur-Einträge.
