const githubRepo = process.env.NUXT_PUBLIC_GITHUB_REPO || 'thaikolja/grok-desktop-app-for-macos'
const appVersion = process.env.NUXT_PUBLIC_APP_VERSION || '1.0.0'

export default defineNuxtConfig({
  site: {
    name: 'Grok Desktop',
    description: 'A native macOS window for grok.com. Not a browser. Not Electron. Not an xAI product.',
    url: process.env.NUXT_SITE_URL || 'http://localhost:3000'
  },
  // Project GitHub Pages uses a base path; robots.txt generation forbids that combo.
  robots: {
    robotsTxt: false
  },
  llms: {
    domain: process.env.NUXT_SITE_URL || 'http://localhost:3000',
    title: 'Grok Desktop',
    description: 'A native macOS window for grok.com. Not a browser. Not Electron. Not an xAI product.'
  },
  app: {
    baseURL: process.env.NUXT_APP_BASE_URL || '/'
  },
  runtimeConfig: {
    public: {
      githubRepo,
      appVersion
    }
  }
})
