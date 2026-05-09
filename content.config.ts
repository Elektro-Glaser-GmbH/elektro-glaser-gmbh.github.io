import { defineContentConfig, defineCollection, z } from '@nuxt/content'

export default defineContentConfig({
  collections: {
    blog: defineCollection({
      type: 'page',
      source: 'blog/**/*.md',
      schema: z.object({
        date: z.string().optional(),
        description: z.string().optional(),
        author: z.string().optional(),
        categories: z.array(z.string()).optional(),
      }),
    }),
  },
})
