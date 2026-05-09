// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-04-26',
  devtools: { enabled: true },

  modules: ['@nuxt/content', 'nuxt-gtag'],

  gtag: {
    id: process.env.GOOGLE_ANALYTICS_MEAS_ID || 'G-XXXXXXXXXX',
    // Consent Mode v2: Script sofort laden, Consent standardmäßig verweigert (DSGVO).
    // Daten werden erst gesendet, nachdem der Nutzer im ConsentBanner zugestimmt hat.
    initCommands: [
      ['consent', 'default', {
        analytics_storage:  'denied',
        ad_storage:         'denied',
        ad_user_data:       'denied',
        ad_personalization: 'denied',
        wait_for_update:    500,
      }],
    ],
  },

  app: {
    head: {
      htmlAttrs: { lang: 'de' },
      meta: [
        { name: 'author', content: 'Elektro-Glaser GmbH' },
        { property: 'og:locale', content: 'de_DE' },
        { property: 'og:site_name', content: 'Elektro-Glaser' },
      ],
      link: [
        { rel: 'icon', href: '/favicon.ico' },
        {
          rel: 'stylesheet',
          href: 'https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Quicksand:wght@500;600;700&family=Work+Sans:wght@600&display=swap',
        },
      ],
    },
  },

  css: ['~/assets/css/main.scss'],

  content: {
    highlight: false,
  },

  runtimeConfig: {
    public: {
      siteUrl: 'https://www.e-glaser.de',
      // E-Mail und Telefon base64-kodiert – wird nur client-seitig dekodiert (Crawler-Schutz)
      contactEmailEncoded: Buffer.from(process.env.CONTACT_EMAIL ?? '').toString('base64'),
      contactPhoneEncoded: Buffer.from(process.env.CONTACT_PHONE ?? '').toString('base64'),
    },
  },
})
