<template>
  <div class="site-wrapper">
    <header class="navbar" :class="{ scrolled }">
      <div class="navbar-inner container">
        <NuxtLink to="/" class="navbar-brand">
          <img src="/logo.svg" alt="Elektro-Glaser Logo" class="navbar-logo" />
        </NuxtLink>
        <nav class="navbar-nav" :class="{ open: menuOpen }">
          <NuxtLink to="/" class="nav-link" @click="menuOpen = false">Startseite</NuxtLink>
          <NuxtLink to="/about" class="nav-link" @click="menuOpen = false">Über uns</NuxtLink>
          <NuxtLink to="/services" class="nav-link" @click="menuOpen = false">Dienstleistungen</NuxtLink>
          <NuxtLink to="/blog" class="nav-link" @click="menuOpen = false">Blog</NuxtLink>
          <NuxtLink to="/contact" class="nav-link" @click="menuOpen = false">Kontakt</NuxtLink>
        </nav>
        <div class="navbar-actions">
          <button class="navbar-burger" :aria-expanded="menuOpen" @click="menuOpen = !menuOpen">
            <span></span><span></span><span></span>
          </button>
        </div>
      </div>
    </header>

    <main class="main-content">
      <slot />
    </main>

    <footer class="site-footer">
      <div class="footer-inner container">
        <div class="footer-brand">
          <img src="/logo.svg" alt="Elektro-Glaser" class="footer-logo" />
          <p>Ihr Partner für Erneuerbare Energien,<br />Smart Home &amp; Elektromobilität in Erlangen.</p>
        </div>
        <div class="footer-links">
          <div class="footer-col">
            <span class="footer-col-title">Seiten</span>
            <NuxtLink to="/">Startseite</NuxtLink>
            <NuxtLink to="/about">Über uns</NuxtLink>
            <NuxtLink to="/services">Dienstleistungen</NuxtLink>
            <NuxtLink to="/blog">Blog</NuxtLink>
          </div>
          <div class="footer-col">
            <span class="footer-col-title">Kontakt</span>
            <a href="tel:+4991319116733">+49 9131 911 6733</a>
            <a href="mailto:info@e-glaser.de">info@e-glaser.de</a>
            <span>Birkenweg 12, 91058 Erlangen</span>
          </div>
        </div>
      </div>
      <div class="footer-bottom container">
        <span>© 2025 Elektro-Glaser GmbH</span>
        <nav class="footer-legal">
          <NuxtLink to="/impressum">Impressum</NuxtLink>
          <NuxtLink to="/datenschutz">Datenschutz</NuxtLink>
        </nav>
      </div>
    </footer>
  </div>
</template>

<script setup lang="ts">
const menuOpen = ref(false)
const scrolled = ref(false)

onMounted(() => {
  const onScroll = () => { scrolled.value = window.scrollY > 20 }
  window.addEventListener('scroll', onScroll, { passive: true })
  onUnmounted(() => window.removeEventListener('scroll', onScroll))
})
</script>
