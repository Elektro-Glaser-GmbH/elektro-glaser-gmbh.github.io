<script setup lang="ts">
withDefaults(defineProps<{
  /** true (Standard): rendert einen klickbaren tel-Link; false: nur Text */
  asLink?: boolean
}>(), {
  asLink: true,
})

const config = useRuntimeConfig()

/** Angezeigtes Format, z. B. "+49 9131 911 6733" */
const display = computed(() => {
  try {
    return atob(config.public.contactPhoneEncoded as string)
  } catch {
    return ''
  }
})

/** E.164-Format für tel:-Link, z. B. "+4991319116733" */
const e164 = computed(() => display.value.replace(/\s+/g, ''))
</script>

<template>
  <!--
    ClientOnly stellt sicher, dass im statisch vorgerenderten HTML weder
    Rufnummer noch tel:-Link erscheint. Crawler sehen nur den leeren Fallback.
    Der Browser dekodiert die base64-kodierte Nummer erst zur Laufzeit.
  -->
  <ClientOnly>
    <a v-if="asLink" :href="`tel:${e164}`">{{ display }}</a>
    <span v-else>{{ display }}</span>
    <template #fallback><span aria-hidden="true"></span></template>
  </ClientOnly>
</template>
