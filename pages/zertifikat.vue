<script setup lang="ts">
useSeoMeta({
  title: 'Signaturprüfung – Elektro-Glaser',
  description: 'So prüfen Sie die digitale Signatur (PAdES) unserer Prüfprotokolle: Zertifikat, SHA256-Fingerprint, DNS, OpenPGP und Git.',
  ogTitle: 'Signaturprüfung – Elektro-Glaser',
  ogDescription: 'So prüfen Sie die digitale Signatur (PAdES) unserer Prüfprotokolle: Zertifikat, SHA256-Fingerprint, DNS, OpenPGP und Git.',
})

// ─────────────────────────────────────────────────────────────────────────────
// OPENPGP_KEY_ID: vollständiger Fingerprint des OpenPGP-Schlüssels auf keys.openpgp.org
// (öffentlicher Teil liegt als public/openpgp_schluessel.asc bei).
// Fingerprint, Gültigkeit und Archiv des X.509-Zertifikats kommen automatisch aus
// public/zertifikate/index.json (gepflegt von scripts/generate-signing-cert.sh).
// Solange dort noch kein Zertifikat steht, erscheint der SHA256-Platzhalter.
// ─────────────────────────────────────────────────────────────────────────────
const SHA256_PLACEHOLDER = '[HIER_SHA256_FINGERPRINT_EINTRAGEN]'
const OPENPGP_KEY_ID = '214AF7FD2FC8A6AF3E543C0088B8848CE9C19294'
const OPENPGP_OWNER = 'Daniel Gerold Glaser'
// Alle auf keys.openpgp.org bestätigten User-IDs des Schlüssels. base64-kodiert wie in
// ObfuscatedEmail.vue: Im vorgerenderten HTML steht kein @, dekodiert wird erst im Browser.
const OPENPGP_EMAILS_B64 = [
  'ZGFuaWVsQGUtZ2xhc2VyLmRl', // e-glaser.de
  'ZGFuaWVsLmdsYXNlckBlbmVyZ2lld2VuZGUtZXJobGFuZ2VuLmRl', // energiewende-erhlangen.de
  'ZGFuaWVsLmdsYXNlckBiaXp6bWFyay5pbw==', // bizzmark.io
  'ZGFuaWVsLmdsYXNlckBjaGFpbnRyb25pY3MuY29t', // chaintronics.com
]
const decodeEmail = (b64: string) => { try { return atob(b64) } catch { return '' } }

const DNS_NAME = '_signatur.e-glaser.de'
const DNS_HISTORY_YEARS = 10
const CERT_FILE = 'oeffentliches_zertifikat.pem'
const PGP_KEY_FILE = 'openpgp_schluessel.asc'
const REPO_URL = 'https://github.com/Elektro-Glaser-GmbH/elektro-glaser-gmbh.github.io'

interface CertEntry {
  year: number
  file: string
  subject: string
  serial: string
  notBefore: string
  notAfter: string
  sha256: string
}

const isPlaceholder = (v: string) => v.startsWith('[')

// Manifest zur Build-Zeit lesen (neuestes Jahr zuerst)
const manifestGlob = import.meta.glob('/public/zertifikate/index.json', { query: '?raw', import: 'default', eager: true })
const manifestRaw = Object.values(manifestGlob)[0] as string | undefined
const certs: CertEntry[] = manifestRaw
  ? (JSON.parse(manifestRaw).certificates as CertEntry[]).sort((a, b) => b.year - a.year)
  : []
const current = certs[0]
const archive = certs.slice(1)

const SHA256_FINGERPRINT = current?.sha256 ?? SHA256_PLACEHOLDER
const currentYear = current?.year ?? new Date().getFullYear()
const exampleYear = archive[0]?.year ?? currentYear

// DNS enthält den Fingerprint ohne Doppelpunkte in Kleinbuchstaben
const toHex = (fp: string) => (isPlaceholder(fp) ? fp : fp.replace(/:/g, '').toLowerCase())
const inDns = (c: CertEntry) => c.year > currentYear - DNS_HISTORY_YEARS

const formatDate = (iso: string) =>
  new Intl.DateTimeFormat('de-DE', { timeZone: 'Europe/Berlin', day: '2-digit', month: '2-digit', year: 'numeric' }).format(new Date(iso))

// Zertifikat + optionale OpenPGP-Signatur zur Build-Zeit aus public/ lesen.
// Fehlt eine Datei noch, liefert glob ein leeres Objekt – der Build bleibt grün.
const certGlob = import.meta.glob('/public/oeffentliches_zertifikat.pem', { query: '?raw', import: 'default', eager: true })
const ascGlob = import.meta.glob('/public/oeffentliches_zertifikat.pem.asc', { query: '?raw', import: 'default', eager: true })
const certPem = (Object.values(certGlob)[0] as string | undefined)?.trim() ?? ''
const hasAsc = Object.keys(ascGlob).length > 0
const pgpGlob = import.meta.glob('/public/openpgp_schluessel.asc', { query: '?raw', import: 'default', eager: true })
const pgpKey = (Object.values(pgpGlob)[0] as string | undefined)?.trim() ?? ''

// Fingerprint in 4er-Gruppen – so zeigen ihn auch gpg und Kleopatra an
const pgpFingerprintGrouped = isPlaceholder(OPENPGP_KEY_ID)
  ? OPENPGP_KEY_ID
  : OPENPGP_KEY_ID.replace(/(.{4})/g, '$1 ').trim().replace(/^((?:\S+ ){4}\S+) /, '$1  ')

const copied = ref<string | null>(null)
async function copy(key: string, text: string) {
  try {
    await navigator.clipboard.writeText(text)
    copied.value = key
    setTimeout(() => { if (copied.value === key) copied.value = null }, 2000)
  } catch {
    copied.value = null
  }
}
</script>

<template>
  <div class="section container">
    <p class="section-label">Digitale Signatur</p>
    <h1>Echtheit unserer Prüfprotokolle prüfen</h1>
    <p class="cert-lead">
      Unsere Prüfprotokolle (z.&nbsp;B. Erst- und Wiederholungsprüfungen nach VDE&nbsp;0100-600 und DIN&nbsp;VDE&nbsp;0105-100)
      versiegeln wir mit einer digitalen Signatur nach dem <strong>PAdES-Standard</strong> (PDF Advanced Electronic
      Signatures). Jede nachträgliche Änderung am Dokument – und sei es nur ein einzelner Messwert – macht die Signatur
      sichtbar ungültig.
    </p>

    <!-- Zertifikat auf einen Blick -->
    <div class="cert-summary">
      <div class="cert-summary-text">
        <span class="cert-summary-label">Unser Signaturzertifikat</span>
        <h2>Elektro-Glaser GmbH – Dokumentensignatur {{ current?.year }}</h2>
        <p v-if="current" class="cert-validity">
          Gültig vom {{ formatDate(current.notBefore) }} bis {{ formatDate(current.notAfter) }}
        </p>
        <p>SHA256-Fingerprint:</p>
        <code class="cert-fingerprint" :class="{ placeholder: isPlaceholder(SHA256_FINGERPRINT) }">{{ SHA256_FINGERPRINT }}</code>
      </div>
      <div class="cert-summary-actions">
        <a :href="`/${CERT_FILE}`" :download="CERT_FILE" class="btn-hero">⬇ Zertifikat herunterladen</a>
        <a v-if="hasAsc" :href="`/${CERT_FILE}.asc`" download class="btn-outline cert-btn-light">OpenPGP-Signatur (.asc)</a>
        <button type="button" class="btn-outline cert-btn-light" @click="copy('fp', SHA256_FINGERPRINT)">
          {{ copied === 'fp' ? '✓ Kopiert' : 'Fingerprint kopieren' }}
        </button>
      </div>
    </div>

    <hr />

    <h2>Warum ist unser Zertifikat „nicht vertrauenswürdig“?</h2>
    <p>
      Wenn Sie ein signiertes Protokoll in Adobe Acrobat oder einem anderen PDF-Programm öffnen, erscheint eventuell der
      Hinweis <em>„Die Identität des Unterzeichners ist unbekannt“</em>. Das ist bei selbst ausgestellten Zertifikaten
      normal und bedeutet <strong>nicht</strong>, dass das Dokument verändert wurde. Es heißt nur, dass Ihr Programm
      unseren Schlüssel noch nicht kennt.
    </p>
    <p>
      Entscheidend ist der <strong>SHA256-Fingerprint</strong>, also der digitale „Fingerabdruck“ unseres Zertifikats. Stimmt
      er mit dem hier veröffentlichten Wert überein, stammt die Signatur nachweislich von uns. Damit Sie sich nicht allein
      auf diese Webseite verlassen müssen, haben wir den Fingerprint an <strong>drei voneinander unabhängigen Stellen</strong>
      hinterlegt:
    </p>

    <div class="usp-row">
      <a href="#dns" class="usp-item cert-way">
        <div class="usp-icon">🌐</div>
        <h4>1. DNS-Eintrag</h4>
        <p>Im Namenssystem unserer Domain – nur wir als Domaininhaber können ihn ändern.</p>
      </a>
      <a href="#openpgp" class="usp-item cert-way">
        <div class="usp-icon">🔑</div>
        <h4>2. OpenPGP-Keyserver</h4>
        <p>Unser Schlüssel liegt öffentlich und verifiziert auf keys.openpgp.org.</p>
      </a>
      <a href="#git" class="usp-item cert-way">
        <div class="usp-icon">🗂️</div>
        <h4>3. Git-Historie</h4>
        <p>Jede Änderung am Zertifikat ist in der Versionsgeschichte dieser Webseite öffentlich nachvollziehbar.</p>
      </a>
    </div>

    <p>
      Wir stellen für <strong>jedes Kalenderjahr ein eigenes Zertifikat</strong> aus, das jeweils am 31.12. um 23:59 Uhr
      abläuft. Maßgeblich für ein Protokoll ist immer das Zertifikat des Jahres, in dem es signiert wurde. Ältere
      Zertifikate finden Sie im <a href="#archiv">Zertifikatsarchiv</a> am Ende dieser Seite.
    </p>

    <hr />

    <h2>So prüfen Sie ein signiertes Protokoll</h2>
    <div class="cert-step">
      <ol>
        <li>Öffnen Sie das PDF in <strong>Adobe Acrobat Reader</strong> (oder einem anderen PAdES-fähigen Programm).</li>
        <li>Klicken Sie oben auf <strong>Unterschriftenbereich</strong> bzw. auf das Signaturfeld im Dokument.</li>
        <li>Wählen Sie <strong>Signatureigenschaften → Zertifikat des Unterzeichners anzeigen</strong>.</li>
        <li>Im Reiter <strong>Details</strong> finden Sie den Eintrag <strong>SHA2-256-Fingerabdruck</strong>.</li>
        <li>Vergleichen Sie diesen Wert mit dem Fingerprint des Jahres, in dem das Protokoll signiert wurde (aktuelles Jahr oben, Vorjahre im <a href="#archiv">Archiv</a>) – und idealerweise mit einer der drei Quellen unten.</li>
        <li>Zusätzlich muss Acrobat melden: <em>„Das Dokument wurde seit Anbringen der Signatur nicht geändert.“</em></li>
      </ol>
    </div>

    <hr />

    <!-- 1. DNS -->
    <section id="dns" class="cert-step">
      <div class="cert-step-head">
        <div class="usp-icon">🌐</div>
        <h2>1. Prüfung über den DNS-Eintrag</h2>
      </div>
      <p>
        Das DNS (Domain Name System) ist das „Telefonbuch des Internets“. Unter unserer Domain
        <strong>e-glaser.de</strong> haben wir einen TXT-Eintrag angelegt, der den Fingerprint unseres Zertifikats enthält.
        Diesen Eintrag kann nur der Inhaber der Domain setzen – eine gefälschte Webseite oder eine manipulierte E-Mail
        kann ihn nicht verändern.
      </p>
      <p><strong>Linux / macOS (Terminal):</strong></p>
      <div class="cert-code">
        <pre><code>dig +short TXT {{ DNS_NAME }}</code></pre>
        <button type="button" class="cert-copy" @click="copy('dig', `dig +short TXT ${DNS_NAME}`)">{{ copied === 'dig' ? '✓' : 'Kopieren' }}</button>
      </div>
      <p><strong>Windows (Eingabeaufforderung / PowerShell):</strong></p>
      <div class="cert-code">
        <pre><code>nslookup -type=TXT {{ DNS_NAME }}</code></pre>
        <button type="button" class="cert-copy" @click="copy('nslookup', `nslookup -type=TXT ${DNS_NAME}`)">{{ copied === 'nslookup' ? '✓' : 'Kopieren' }}</button>
      </div>
      <p>Erwartete Antwort (aktuelles Zertifikat {{ currentYear }}):</p>
      <div class="cert-code">
        <pre><code>"v=sig1; y={{ currentYear }}; alg=sha256; fp=<span :class="{ placeholder: isPlaceholder(SHA256_FINGERPRINT) }">{{ toHex(SHA256_FINGERPRINT) }}</span>"</code></pre>
      </div>
      <p>
        <strong>Ältere Protokolle:</strong> Für jedes Jahr gibt es zusätzlich einen eigenen Eintrag, in dem die Jahreszahl
        vorangestellt ist – so lässt sich auch ein Protokoll aus einem Vorjahr prüfen. Wir halten diese Einträge
        {{ DNS_HISTORY_YEARS }}&nbsp;Jahre lang vor. Beispiel für {{ exampleYear }}:
      </p>
      <div class="cert-code">
        <pre><code>dig +short TXT {{ exampleYear }}.{{ DNS_NAME }}</code></pre>
        <button type="button" class="cert-copy" @click="copy('digy', `dig +short TXT ${exampleYear}.${DNS_NAME}`)">{{ copied === 'digy' ? '✓' : 'Kopieren' }}</button>
      </div>
      <p class="hint">
        Im DNS steht der Fingerprint ohne Doppelpunkte und in Kleinbuchstaben – inhaltlich ist es derselbe Wert.
        Ohne Terminal können Sie auch einen Online-Dienst wie
        <a href="https://toolbox.googleapps.com/apps/dig/#TXT/_signatur.e-glaser.de" target="_blank" rel="noopener">Google Admin Toolbox Dig</a>
        verwenden.
      </p>
    </section>

    <!-- 2. OpenPGP -->
    <section id="openpgp" class="cert-step">
      <div class="cert-step-head">
        <div class="usp-icon">🔑</div>
        <h2>2. Prüfung über den OpenPGP-Keyserver</h2>
      </div>
      <p>
        Zusätzlich verwenden wir den OpenPGP-Schlüssel unseres Geschäftsführers Daniel Glaser. Er ist auf dem
        unabhängigen, öffentlichen Schlüsselverzeichnis
        <a href="https://keys.openpgp.org" target="_blank" rel="noopener">keys.openpgp.org</a> hinterlegt und dort per
        E-Mail-Bestätigung für alle unten aufgeführten Adressen verifiziert. Mit diesem Schlüssel signieren wir unsere
        Zertifikatsdatei – so lässt sich unabhängig von dieser Webseite belegen, dass die Datei von uns stammt.
      </p>
      <p>
        <strong>Fingerprint:</strong>
        <code class="cert-inline" :class="{ placeholder: isPlaceholder(OPENPGP_KEY_ID) }">{{ pgpFingerprintGrouped }}</code><br />
        <strong>Inhaber:</strong> {{ OPENPGP_OWNER }}
      </p>
      <p class="cert-email-label"><strong>E-Mail-Adressen dieses Schlüssels</strong> (auf keys.openpgp.org bestätigt):</p>
      <ClientOnly>
        <ul class="cert-email-list">
          <li v-for="b64 in OPENPGP_EMAILS_B64" :key="b64">
            <a :href="`mailto:${decodeEmail(b64)}`">{{ decodeEmail(b64) }}</a>
          </li>
        </ul>
        <template #fallback><p class="cert-muted">E-Mail-Adressen werden geladen …</p></template>
      </ClientOnly>
      <p class="hint">
        Primäre Adresse ist daniel@e-glaser.de – sie erscheint beim Prüfen einer Signatur als Unterzeichner. Download und
        Keyserver enthalten denselben Schlüssel mit identischem Fingerprint.
      </p>
      <p class="cert-btn-row">
        <a :href="`https://keys.openpgp.org/search?q=${encodeURIComponent(OPENPGP_KEY_ID)}`" target="_blank" rel="noopener" class="btn-outline">
          Schlüssel auf keys.openpgp.org ansehen ↗
        </a>
        <a v-if="pgpKey" :href="`/${PGP_KEY_FILE}`" :download="PGP_KEY_FILE" class="btn-outline">⬇ Öffentlichen Schlüssel herunterladen</a>
        <a v-if="hasAsc" :href="`/${CERT_FILE}.asc`" download class="btn-outline">⬇ Signatur der Zertifikatsdatei (.asc)</a>
      </p>
      <p><strong>Für Fachleute – Schlüssel abrufen und Signatur der Zertifikatsdatei prüfen:</strong></p>
      <div class="cert-code">
        <pre><code>gpg --keyserver hkps://keys.openpgp.org --recv-keys <span :class="{ placeholder: isPlaceholder(OPENPGP_KEY_ID) }">{{ OPENPGP_KEY_ID }}</span>
# alternativ die Datei von dieser Seite: gpg --import {{ PGP_KEY_FILE }}
gpg --verify {{ CERT_FILE }}.asc {{ CERT_FILE }}</code></pre>
      </div>
      <template v-if="pgpKey">
        <p>Öffentlicher OpenPGP-Schlüssel:</p>
        <div class="cert-code">
          <pre><code>{{ pgpKey }}</code></pre>
          <button type="button" class="cert-copy" @click="copy('pgp', pgpKey)">{{ copied === 'pgp' ? '✓' : 'Kopieren' }}</button>
        </div>
      </template>
    </section>

    <!-- 3. Git -->
    <section id="git" class="cert-step">
      <div class="cert-step-head">
        <div class="usp-icon">🗂️</div>
        <h2>3. Prüfung über die Git-Versionsgeschichte</h2>
      </div>
      <p>
        Diese Webseite wird aus einem öffentlichen Git-Repository auf GitHub erzeugt. Git speichert jede Änderung mit
        Zeitstempel und kryptografischer Prüfsumme. Das öffentliche Zertifikat ist dort versioniert: Würde es jemand
        heimlich austauschen, wäre das in der Historie sofort sichtbar.
      </p>
      <p>
        <a :href="`${REPO_URL}/commits/main/public/${CERT_FILE}`" target="_blank" rel="noopener" class="btn-outline">
          Änderungshistorie auf GitHub ansehen ↗
        </a>
      </p>
      <div class="cert-code">
        <pre><code>git clone {{ REPO_URL }}.git
git log --follow -p -- public/{{ CERT_FILE }}
git log --stat -- public/zertifikate/</code></pre>
      </div>
    </section>

    <hr />

    <!-- Zertifikat -->
    <section id="zertifikat" class="cert-step">
      <div class="cert-step-head">
        <div class="usp-icon">📄</div>
        <h2>Öffentliches Zertifikat (PEM)</h2>
      </div>
      <p>
        Das öffentliche Zertifikat enthält <strong>keinen</strong> geheimen Schlüssel und darf frei weitergegeben werden.
        Netzbetreiber und Auftraggeber können es in ihre PDF-Software als vertrauenswürdige Identität importieren – danach
        werden unsere Signaturen direkt als gültig angezeigt.
      </p>
      <p>
        <a :href="`/${CERT_FILE}`" :download="CERT_FILE" class="btn-primary">⬇ {{ CERT_FILE }} herunterladen</a>
      </p>
      <div v-if="certPem" class="cert-code">
        <pre><code>{{ certPem }}</code></pre>
        <button type="button" class="cert-copy" @click="copy('pem', certPem)">{{ copied === 'pem' ? '✓' : 'Kopieren' }}</button>
      </div>
      <p v-else class="cert-code-missing placeholder">
        [ZERTIFIKAT FEHLT – scripts/generate-signing-cert.sh ausführen, erzeugt public/{{ CERT_FILE }}]
      </p>
      <p>Fingerprint der heruntergeladenen Datei selbst berechnen:</p>
      <div class="cert-code">
        <pre><code>openssl x509 -in {{ CERT_FILE }} -noout -fingerprint -sha256</code></pre>
        <button type="button" class="cert-copy" @click="copy('ossl', `openssl x509 -in ${CERT_FILE} -noout -fingerprint -sha256`)">{{ copied === 'ossl' ? '✓' : 'Kopieren' }}</button>
      </div>
      <p class="hint">
        Fragen zur Signatur oder Hinweise auf Unstimmigkeiten? <NuxtLink to="/contact">Kontaktieren Sie uns</NuxtLink> –
        bei Abweichungen des Fingerprints bitte das Dokument nicht verwenden.
      </p>
    </section>

    <!-- Archiv -->
    <section id="archiv" class="cert-step">
      <div class="cert-step-head">
        <div class="usp-icon">🗄️</div>
        <h2>Zertifikatsarchiv</h2>
      </div>
      <p>
        Alle bisher verwendeten Signaturzertifikate. Abgelaufene Zertifikate werden nicht mehr zum Signieren genutzt;
        Protokolle, die während ihrer Gültigkeit signiert wurden, lassen sich damit aber weiterhin prüfen.
      </p>
      <div v-if="certs.length" class="cert-table-wrap">
        <table class="cert-table">
          <thead>
            <tr>
              <th>Jahr</th>
              <th>Gültigkeit</th>
              <th>SHA256-Fingerprint</th>
              <th>DNS-Eintrag</th>
              <th>Download</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="c in certs" :key="c.year" :class="{ 'is-current': c === current }">
              <td>
                <strong>{{ c.year }}</strong>
                <span v-if="c === current" class="blog-tag">aktuell</span>
              </td>
              <td class="cert-nowrap">{{ formatDate(c.notBefore) }} –<br />{{ formatDate(c.notAfter) }}</td>
              <td><code class="cert-fp-small">{{ c.sha256 }}</code></td>
              <td>
                <code v-if="inDns(c)" class="cert-fp-small">{{ c.year }}.{{ DNS_NAME }}</code>
                <span v-else class="cert-muted">nicht mehr im DNS</span>
              </td>
              <td><a :href="`/${c.file}`" download class="cert-nowrap">⬇ PEM</a></td>
            </tr>
          </tbody>
        </table>
      </div>
      <p v-else class="cert-code-missing placeholder">
        [NOCH KEINE ZERTIFIKATE – scripts/generate-signing-cert.sh ausführen]
      </p>
      <p v-if="archive.length === 0 && certs.length" class="hint">Bisher gibt es noch keine archivierten Vorjahres-Zertifikate.</p>
    </section>
  </div>
</template>
