# Changelog

All notable changes to Grok Desktop for macOS are listed here.

## 1.0.0 — 2026-09-07

First public release. A native macOS window for [grok.com](https://grok.com). Not a browser. Not a flimsy Electron port. Not an xAI product.

This is the first stable cut. Treat it that way. Sign-in and the window work — but first releases still ship surprises. If something breaks, use **← Grok**, reload, or quit and reopen.

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

### Fixed

Sign-in bugs closed before this cut. They are not supposed to come back:

- Closing the overlay too early aborted Google’s `?code=` callback
- Reloading the main view replayed the OAuth callback onto grok.com
- Re-issuing a POST through `webView.load()` dropped the HTTP body (Google 400, dead Back)
- Auth popups must use WebKit’s own configuration so `window.opener` and POST survive
- Opening `google.de` / `youtube.com` in Chrome stole the cookie jar from this app
- grok.com’s SPA needed a cache-ignoring reload of `https://grok.com` after login

### Intentionally not included

- Tabs
- An address bar
- Back and forward buttons on the main window
- Shipping Chromium so a website can appear on a desktop
- Notarization / Developer ID
- Homebrew

### Notes

- Requires macOS 14 Sonoma or later. One universal file for Apple Silicon and Intel.
- The CI build is ad-hoc signed, not notarized. First open: Control-click → **Open**.
- If Chrome or Safari opens during Google sign-in, that login belongs to the browser. Close it, click **← Grok**, and sign in again in Grok Desktop.
