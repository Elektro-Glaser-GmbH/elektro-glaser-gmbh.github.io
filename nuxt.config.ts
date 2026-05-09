// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-04-26',
  devtools: { enabled: true },

  modules: ['@nuxt/content', 'nuxt-gtag'],

  gtag: {
    // Script wird erst nach expliziter Zustimmung geladen (DSGVO)
    initMode: 'manual',
    id: process.env.GOOGLE_ANALYTICS_MEAS_ID || 'G-XXXXXXXXXX',
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
      // E-Mail base64-kodiert – wird nur client-seitig dekodiert (Crawler-Schutz)
      contactEmailEncoded: Buffer.from(process.env.CONTACT_EMAIL ?? '').toString('base64'),
    },
  },
})
