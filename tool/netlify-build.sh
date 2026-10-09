#!/usr/bin/env bash
# Netlify build: install the current stable Flutter SDK and build the web app.
# The Netlify build image doesn't ship Flutter, so the SDK is downloaded from
# the official release archive (same stable channel CI uses).
set -euo pipefail

FLUTTER_HOME="$HOME/flutter"
RELEASE_INFO="$FLUTTER_HOME/.netlify-release.json"
RELEASES=https://storage.googleapis.com/flutter_infra_release/releases

# Reinstall if the SDK is missing or was installed without release metadata.
if [ ! -x "$FLUTTER_HOME/bin/flutter" ] || [ ! -f "$RELEASE_INFO" ]; then
  rm -rf "$FLUTTER_HOME"
  # Pick the current stable release, e.g. "stable/linux/flutter_linux_X-stable.tar.xz".
  RELEASE=$(curl -fsSL "$RELEASES/releases_linux.json" | node -e '
    let s = "";
    process.stdin.on("data", (d) => (s += d)).on("end", () => {
      const j = JSON.parse(s);
      console.log(JSON.stringify(j.releases.find((r) => r.hash === j.current_release.stable)));
    });
  ')
  ARCHIVE=$(node -p 'JSON.parse(process.argv[1]).archive' "$RELEASE")
  echo "Downloading Flutter: $ARCHIVE"
  curl -fsSL "$RELEASES/$ARCHIVE" | tar -xJ -C "$HOME"
  printf '%s' "$RELEASE" > "$RELEASE_INFO"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"

# First run bootstraps the Flutter tool (and clears its version cache).
flutter config --no-analytics

# Flutter normally works out its own version by running git commands against
# the SDK checkout. Some build sandboxes restrict git, which leaves the SDK as
# "0.0.0-unknown" and breaks dependency resolution. Writing the version cache
# from the release metadata lets Flutter skip those git calls.
node -e '
  const fs = require("fs");
  const root = process.argv[1];
  const r = JSON.parse(fs.readFileSync(root + "/.netlify-release.json", "utf8"));
  const engine = fs.readFileSync(root + "/bin/internal/engine.version", "utf8").trim();
  fs.writeFileSync(root + "/bin/cache/flutter.version.json", JSON.stringify({
    frameworkVersion: r.version,
    channel: "stable",
    repositoryUrl: "https://github.com/flutter/flutter.git",
    frameworkRevision: r.hash,
    frameworkCommitDate: r.release_date,
    engineRevision: engine,
    dartSdkVersion: r.dart_sdk_version,
    devToolsVersion: "unknown",
    flutterVersion: r.version,
  }, null, 2));
' "$FLUTTER_HOME"
printf '%s' "$(node -p 'require(process.argv[1]).version' "$RELEASE_INFO")" > "$FLUTTER_HOME/version"

flutter --version
flutter pub get
flutter build web --release
