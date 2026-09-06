# Grok Desktop for macOS

**v1.0.0** — a native window for [grok.com](https://grok.com), by **Kolja Nolte**.

![screenshot-2](https://p.ipic.vip/6f5rst.jpg)

macOS only. Swift and WebKit. No Electron, no Chromium, no Node. One window, traffic lights, the page. Not a browser.

This app is **not affiliated with xAI**.

- User guide: [https://thaikolja.github.io/grok-desktop-app-for-macos/](https://thaikolja.github.io/grok-desktop-app-for-macos/)
- Downloads: [Releases](https://github.com/thaikolja/grok-desktop-app-for-macos/releases)

GitHub Actions builds a **universal** `.app` (Apple Silicon and Intel), a `.dmg`, a `.zip` of the app, and deploys the docs. That happens when a tag like `v1.0.0` is pushed, and only if the macOS build succeeds.

## Requirements

- macOS 14 Sonoma or later (Apple Silicon or Intel)
- To build locally: Xcode 16 or later (the full app, not only Command Line Tools)

![screenshot-1](https://p.ipic.vip/wi2aaf.png)

## Quick start

1. Download `Grok-Desktop-*-universal.dmg` from [Releases](https://github.com/thaikolja/grok-desktop-app-for-macos/releases).
2. Open it, drag **Grok Desktop** into Applications – done!

The first open may need Control-click → **Open**. The CI build is ad-hoc signed, not notarized.

There is one file for M chips and Intel. You do not pick an architecture.

This is the first public release. Bugs can happen. If something breaks, use **← Grok**, reload, or quit and reopen.

## Open from source

1. Open `GrokDesktop.xcodeproj` in Xcode.
2. If Xcode asks you to Trust, do that.
3. Destination: **My Mac**.
4. Signing: your Team, or **Sign to Run Locally**.
5. Press **⌘R**.

The first launch opens `https://grok.com`. Sign in on the page. Stay in this app — if Chrome takes over, that login belongs to Chrome, not to Grok Desktop.

## Shortcuts

| Shortcut | Action |
| --- | --- |
| ⌘R | Reload |
| ⌘. | Stop |
| ⌘F | Find |
| ⌘U | Usage stats |
| ⌥⌘P | Always on top |
| ⌘+ / ⌘- / ⌘0 | Zoom |
| ⌘P | Print |

## Build from the command line

Local Debug (this machine’s architecture):

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -project GrokDesktop.xcodeproj -scheme GrokDesktop \
  -configuration Debug -destination 'platform=macOS,arch=arm64' \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_ALLOWED=YES build
```

Universal Release (Apple Silicon + Intel), the same path GitHub Actions uses:

```bash
./scripts/package-macos.sh
```

Artifacts land in `dist/`. Do not commit them.

## Docs site

Published automatically after a successful release build:

[https://thaikolja.github.io/grok-desktop-app-for-macos/](https://thaikolja.github.io/grok-desktop-app-for-macos/)

Local preview:

```bash
cd docs
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

## License

GNU GPL v2. See `LICENSE`.

© 2026 Kolja Nolte
