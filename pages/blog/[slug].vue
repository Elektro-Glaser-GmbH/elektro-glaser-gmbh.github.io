<script setup lang="ts">
const route = useRoute()
const { data: post } = await useAsyncData(`blog-${route.params.slug}`, () =>
  queryCollection('blog').path(`/blog/${route.params.slug}`).first()
)

if (!post.value) {
  throw createError({ statusCode: 404, statusMessage: 'Beitrag nicht gefunden' })
}

useSeoMeta({
  title: () => `${post.value?.title} – Elektro-Glaser`,
  description: () => post.value?.description,
  ogTitle: () => post.value?.title,
  ogDescription: () => post.value?.description,
})
</script>

<template>
  <div class="section container prose">
    <NuxtLink to="/blog" class="back-link">← Zurück zum Blog</NuxtLink>

    <div v-if="post" class="blog-header">
      <p class="section-label">Blog</p>
      <h1>{{ post.title }}</h1>
      <div class="blog-meta">
        <time v-if="post.date" :datetime="post.date">
          {{ new Date(post.date).toLocaleDateString('de-DE', { year: 'numeric', month: 'long', day: 'numeric' }) }}
        </time>
        <span v-if="post.author">· {{ post.author }}</span>
        <span v-if="post.categories" class="blog-categories">
          <span v-for="cat in post.categories" :key="cat" class="blog-tag">{{ cat }}</span>
        </span>
      </div>
    </div>

    <ContentRenderer v-if="post" :value="post" />
  </div>
</template>
