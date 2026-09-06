export default defineAppConfig({
  docus: {
    name: 'Grok Desktop',
    description: 'A native macOS window for grok.com. Not a browser. Not Electron. Not an xAI product.',
    url: 'https://thaikolja.github.io/grok-desktop-app-for-macos'
  },
  header: {
    title: 'Grok Desktop'
  },
  github: {
    url: 'https://github.com/thaikolja/grok-desktop-app-for-macos',
    branch: 'main',
    rootDir: 'docs'
  },
  ui: {
    colors: {
      primary: 'neutral',
      neutral: 'zinc'
    }
  }
})
