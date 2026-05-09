<script setup lang="ts">
withDefaults(defineProps<{
  /** true (Standard): rendert einen klickbaren mailto-Link; false: nur Text */
  asLink?: boolean
}>(), {
  asLink: true,
})

const config = useRuntimeConfig()
const email = computed(() => {
  try {
    return atob(config.public.contactEmailEncoded as string)
  } catch {
    return ''
  }
})
</script>

<template>
  <!--
    ClientOnly stellt sicher, dass im statisch vorgerenderten HTML kein @-Zeichen
    und kein mailto:-Link erscheint. Crawler sehen nur den leeren Fallback-Slot.
    Der Browser dekodiert die base64-kodierte Adresse erst zur Laufzeit.
  -->
  <ClientOnly>
    <a v-if="asLink" :href="`mailto:${email}`">{{ email }}</a>
    <span v-else>{{ email }}</span>
    <template #fallback><span aria-hidden="true"></span></template>
  </ClientOnly>
</template>
