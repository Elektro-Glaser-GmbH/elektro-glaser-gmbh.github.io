import { defineContentConfig, defineCollection, z } from '@nuxt/content'

export default defineContentConfig({
  collections: {
    blog: defineCollection({
      type: 'page',
      source: 'blog/**/*.md',
      schema: z.object({
        date: z.string(),
        description: z.string(),
        author: z.string().optional(),
        categories: z.array(z.string()).default([]),
      }),
    }),
    pages: defineCollection({
      type: 'page',
      source: '*.md',
      schema: z.object({
        description: z.string().optional(),
      }),
    }),
  },
})
