<script setup lang="ts">
useSeoMeta({
  title: 'Kontakt – Elektro-Glaser',
  description: 'Nehmen Sie Kontakt mit Elektro-Glaser auf – wir freuen uns auf Ihre Anfrage.',
  ogTitle: 'Kontakt – Elektro-Glaser',
  ogDescription: 'Nehmen Sie Kontakt mit Elektro-Glaser auf – wir freuen uns auf Ihre Anfrage.',
})

const form = reactive({
  name: '',
  email: '',
  phone: '',
  subject: '',
  message: '',
  honeypot: '',
})
</script>

<template>
  <div class="section container">
    <p class="section-label">Kontakt</p>
    <h1>Nimm Kontakt mit uns auf</h1>
    <hr />

    <div class="contact-box">
      <div class="contact-item">
        <div class="contact-item-label">📞 Telefon</div>
        <div class="contact-item-value"><a href="tel:+4991319116733">+49 9131 911 6733</a></div>
      </div>
      <div class="contact-item">
        <div class="contact-item-label">✉️ E-Mail</div>
        <div class="contact-item-value"><ObfuscatedEmail /></div>
      </div>
      <div class="contact-item">
        <div class="contact-item-label">📍 Adresse</div>
        <div class="contact-item-value">Birkenweg 12, 91058 Erlangen</div>
      </div>
      <div class="contact-item">
        <div class="contact-item-label">🌐 Web</div>
        <div class="contact-item-value"><a href="https://www.e-glaser.de" target="_blank" rel="noopener">www.e-glaser.de</a></div>
      </div>
    </div>

    <hr />
    <h2>Schreiben Sie uns</h2>
    <p>Nutzen Sie gerne unser Kontaktformular – wir melden uns in der Regel innerhalb eines Werktages:</p>

    <form
      action="https://api.staticforms.dev/submit"
      method="POST"
      class="contact-form"
    >
      <!-- StaticForms API-Key -->
      <input type="hidden" name="apiKey" value="YOUR_STATICFORMS_API_KEY" />
      <input type="hidden" name="redirectTo" value="https://www.e-glaser.de/danke" />
      <!-- Honeypot gegen Spam -->
      <input type="text" name="honeypot" style="display:none" tabindex="-1" autocomplete="off" />

      <div class="form-group">
        <label for="name">Name *</label>
        <input id="name" v-model="form.name" type="text" name="name" required />
      </div>
      <div class="form-group">
        <label for="email">E-Mail *</label>
        <input id="email" v-model="form.email" type="email" name="email" required />
      </div>
      <div class="form-group">
        <label for="phone">Telefon</label>
        <input id="phone" v-model="form.phone" type="tel" name="phone" />
      </div>
      <div class="form-group">
        <label for="subject">Betreff</label>
        <input
          id="subject"
          v-model="form.subject"
          type="text"
          name="subject"
          placeholder="z. B. Anfrage Wallbox, PV-Anlage, ..."
        />
      </div>
      <div class="form-group">
        <label for="message">Nachricht *</label>
        <textarea id="message" v-model="form.message" name="message" rows="6" required></textarea>
      </div>
      <button type="submit" class="btn-hero">Nachricht senden</button>
    </form>

    <p class="hint">
      Das Formular nutzt <a href="https://www.staticforms.dev" target="_blank" rel="noopener">Static Forms</a> als Backend.
    </p>
  </div>
</template>
