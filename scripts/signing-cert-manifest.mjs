#!/usr/bin/env node
// ── Elektro-Glaser – Zertifikats-Manifest (public/zertifikate/index.json) ─────
// Hilfsskript für scripts/generate-signing-cert.sh:
//   node scripts/signing-cert-manifest.mjs add <jahr> <pem-datei>   Eintrag hinzufügen
//   node scripts/signing-cert-manifest.mjs dns                      DNS-TXT-Einträge ausgeben
// ─────────────────────────────────────────────────────────────────────────────
import { X509Certificate } from 'node:crypto'
import { readFileSync, writeFileSync, existsSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const REPO_ROOT = join(dirname(fileURLToPath(import.meta.url)), '..')
const MANIFEST = join(REPO_ROOT, 'public/zertifikate/index.json')
const DNS_NAME = '_signatur.e-glaser.de'
const DNS_HISTORY_YEARS = 10
const DNS_TTL = 3600

const load = () => (existsSync(MANIFEST) ? JSON.parse(readFileSync(MANIFEST, 'utf8')) : { certificates: [] })

const txtValue = c => `v=sig1; y=${c.year}; alg=sha256; fp=${c.sha256.replace(/:/g, '').toLowerCase()}`

function add(year, pemPath) {
  const cert = new X509Certificate(readFileSync(pemPath))
  const manifest = load()
  const y = Number(year)
  if (manifest.certificates.some(c => c.year === y)) {
    throw new Error(`Für ${y} existiert bereits ein Eintrag im Manifest.`)
  }
  manifest.certificates.push({
    year: y,
    file: `zertifikate/elektro-glaser-signatur-${y}.pem`,
    subject: cert.subject.replace(/\n/g, ', '),
    serial: cert.serialNumber,
    notBefore: new Date(cert.validFrom).toISOString(),
    notAfter: new Date(cert.validTo).toISOString(),
    sha256: cert.fingerprint256,
  })
  manifest.certificates.sort((a, b) => b.year - a.year)
  writeFileSync(MANIFEST, JSON.stringify(manifest, null, 2) + '\n')
}

function dns() {
  const certs = load().certificates
  if (!certs.length) throw new Error('Manifest ist leer.')
  const current = certs[0]
  const keep = certs.filter(c => c.year > current.year - DNS_HISTORY_YEARS)
  const drop = certs.filter(c => c.year <= current.year - DNS_HISTORY_YEARS)
  const pad = `${current.year}.${DNS_NAME}.`.length + 2
  const line = (name, c) => `${`${name}.`.padEnd(pad)}${DNS_TTL} IN TXT "${txtValue(c)}"`

  console.log(`; Aktuelles Zertifikat (${current.year})`)
  console.log(line(DNS_NAME, current))
  console.log(`; Jahres-Einträge (${DNS_HISTORY_YEARS} Jahre Historie)`)
  for (const c of keep) console.log(line(`${c.year}.${DNS_NAME}`, c))
  if (drop.length) {
    console.log('; Diese Einträge können aus dem DNS gelöscht werden:')
    for (const c of drop) console.log(`;   ${c.year}.${DNS_NAME}`)
  }
}

const [cmd, ...args] = process.argv.slice(2)
try {
  if (cmd === 'add' && args.length === 2) add(...args)
  else if (cmd === 'dns') dns()
  else throw new Error('Verwendung: signing-cert-manifest.mjs add <jahr> <pem> | dns')
} catch (e) {
  console.error(`❌ ${e.message}`)
  process.exit(1)
}
