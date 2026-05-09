<script setup lang="ts">
useSeoMeta({
  title: 'Vielen Dank! – Elektro-Glaser',
  description: 'Ihre Nachricht wurde erfolgreich übermittelt.',
})
</script>

<template>
  <div class="section container" style="text-align:center; padding: 4rem 1rem;">
    <h2>✅ Nachricht erfolgreich gesendet!</h2>
    <p>
      Vielen Dank für Ihre Anfrage. Wir haben Ihre Nachricht erhalten und melden uns in der Regel
      <strong>innerhalb eines Werktages</strong> bei Ihnen.
    </p>
    <p>Bei dringenden Anliegen erreichen Sie uns direkt:</p>
    <p>
      📞 <a href="tel:+4991319116733">+49 9131 911 6733</a> · ✉️
      <ObfuscatedEmail />
    </p>
    <NuxtLink to="/" class="btn-hero" style="margin-top:1.5rem;display:inline-block;">
      Zurück zur Startseite
    </NuxtLink>
  </div>
</template>
