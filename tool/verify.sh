#!/usr/bin/env bash
# The project's local gate: the exact checks CI's verify job runs.
# Used before every PR and by .githooks/pre-push.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo "▸ flutter analyze"
flutter analyze

echo "▸ flutter test"
flutter test
