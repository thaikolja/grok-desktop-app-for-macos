# Changelog

All notable changes to Grok Desktop for macOS are listed here.

## 1.0.0 — 2026-09-07

First stable release. A native macOS window for [grok.com](https://grok.com). Not a browser. Not a flimsy Electron port. Not an xAI product.

### Added

- Single window that opens grok.com in WebKit (the same engine Safari uses)
- Sign in with xAI, Google, or Apple on the page, inside the app
- **← Grok** control whenever you leave grok.com, always returning to the start page
- After a successful sign-in, the home page reloads so you actually look signed in
- Always on top
- Optional usage stats bar (fetched with your grok.com session)
- Optional menu bar extra
- Find on page (⌘F), zoom, print, reload
- Settings for zoom and Safari user agent
- Camera and microphone prompts only for grok.com speech/video features
- GitHub Actions release: universal `.app` (arm64 + x86_64), DMG, zip of the `.app`, then Docus to GitHub Pages — docs deploy only after the macOS artifacts succeed
- Published downloads: [Releases](https://github.com/thaikolja/grok-desktop-app-for-macos/releases)
- Published docs: [https://thaikolja.github.io/grok-desktop-app-for-macos/](https://thaikolja.github.io/grok-desktop-app-for-macos/)

### Intentionally not included

- Tabs
- An address bar
- Back and forward buttons on the main window
- Shipping Chromium so a website can appear on a desktop
