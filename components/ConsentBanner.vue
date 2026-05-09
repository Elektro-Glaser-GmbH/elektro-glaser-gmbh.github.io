<script setup lang="ts">
const { gtag } = useGtag()

// Consent-Status persistent im Cookie speichern (1 Jahr)
const consent = useCookie<boolean | null>('eg-cookie-consent', {
  default: () => null,
  maxAge: 365 * 24 * 60 * 60,
  sameSite: 'lax',
})

const showBanner = computed(() => consent.value === null)

// Bei erneutem Seitenaufruf: gespeicherten Consent wiederherstellen
onMounted(() => {
  if (consent.value === true) {
    gtag('consent', 'update', {
      analytics_storage:  'granted',
      ad_storage:         'granted',
      ad_user_data:       'granted',
      ad_personalization: 'granted',
    })
  }
})

function acceptAll() {
  consent.value = true
  // Consent Mode v2: Datenerfassung freigeben
  gtag('consent', 'update', {
    analytics_storage:  'granted',
    ad_storage:         'granted',
    ad_user_data:       'granted',
    ad_personalization: 'granted',
  })
}

function denyAll() {
  consent.value = false
}
</script>

<template>
  <Teleport to="body">
    <div v-if="showBanner" class="consent-banner" role="dialog" aria-label="Cookie-Einstellungen">
      <div class="consent-banner__content">
        <div class="consent-banner__text">
          <strong>Datenschutzhinweis</strong>
          <p>
            Wir verwenden Google Analytics (GA4), um die Nutzung unserer Website zu analysieren und zu verbessern.
            Dabei werden Daten an Google übertragen. Ihre Einwilligung können Sie jederzeit im
            <NuxtLink to="/datenschutz">Datenschutzhinweis</NuxtLink> widerrufen.
          </p>
        </div>
        <div class="consent-banner__actions">
          <button class="consent-btn consent-btn--deny" @click="denyAll">Ablehnen</button>
          <button class="consent-btn consent-btn--accept" @click="acceptAll">Zustimmen</button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<style scoped>
.consent-banner {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  z-index: 9999;
  background: #0f172a;
  color: #f8f9fa;
  padding: 1.25rem 1.5rem;
  box-shadow: 0 -2px 20px rgba(0, 0, 0, 0.3);
}

.consent-banner__content {
  max-width: 960px;
  margin: 0 auto;
  display: flex;
  align-items: center;
  gap: 2rem;
  flex-wrap: wrap;
}

.consent-banner__text {
  flex: 1;
  min-width: 0;
}

.consent-banner__text strong {
  display: block;
  font-size: 0.95rem;
  margin-bottom: 0.25rem;
  color: #ffffff;
}

.consent-banner__text p {
  margin: 0;
  font-size: 0.875rem;
  line-height: 1.55;
  color: rgba(255, 255, 255, 0.75);
}

.consent-banner__text a {
  color: #eaaf03;
  text-decoration: underline;
}

.consent-banner__actions {
  display: flex;
  gap: 0.75rem;
  flex-shrink: 0;
}

.consent-btn {
  padding: 0.55rem 1.35rem;
  border-radius: 6px;
  font-size: 0.9rem;
  font-weight: 600;
  cursor: pointer;
  transition: opacity 0.15s;
  white-space: nowrap;
}

.consent-btn:hover {
  opacity: 0.85;
}

.consent-btn--accept {
  background: #eaaf03;
  color: #0f172a;
  border: none;
}

.consent-btn--deny {
  background: transparent;
  color: rgba(255, 255, 255, 0.7);
  border: 1px solid rgba(255, 255, 255, 0.25);
}

@media (max-width: 600px) {
  .consent-banner__content {
    flex-direction: column;
    gap: 1rem;
  }

  .consent-banner__actions {
    width: 100%;
    justify-content: flex-end;
  }
}
</style>
