# Sudoku — Firefox / Chrome extension

Popup extension that embeds the Flutter web build of the game.
One MV3 `manifest.json` loads in both Firefox (128+) and Chrome.

## Rebuild after app changes

From the Flutter project root:

```sh
flutter build web --release --pwa-strategy=none
rm -rf extension/app
mkdir extension/app
cp -r build/web/. extension/app/
rm -f extension/app/flutter_service_worker.js
```

(Service workers can't register from extension pages, hence
`--pwa-strategy=none` plus dropping the file.)

## Test locally (no signing needed)

Firefox: open `about:debugging` → This Firefox → Load Temporary Add-on →
pick `extension/manifest.json`. Click the toolbar icon to play.

Chrome: open `chrome://extensions` → Developer mode → Load unpacked →
pick `extension/`.

## Publish to addons.mozilla.org (signed = "deployed")

1. Get API credentials: https://addons.mozilla.org/developers/addon/api/key/
2. Sign + submit:

```sh
npx web-ext sign --source-dir=extension \
  --api-key <KEY> --api-secret <SECRET> --channel listed
```

`--channel listed` publishes publicly; use `unlisted` for a signed
self-distributed `.xpi`. Temporary add-ons stop working on browser
restart — only signed builds persist.
