#!/usr/bin/env bash
# Print one page of the built docs site to a PDF with headless Chromium,
# after sofleii's .github/scripts/print-keymap-pdf.sh. Used for the Sofle
# keymap printout by `mise run docs-sofle-pdf`, locally and in CI.
#
#   print-page-pdf.sh <built site dir> <page path> <output pdf>
#   print-page-pdf.sh site/public sofle/print/ site/public/pdf/sofle-keymap.pdf
#
# The site is served over HTTP on 127.0.0.1, not opened as file://, so the
# root-relative font, CSS and image URLs resolve (the site has no subpath).
set -euo pipefail

usage="usage: print-page-pdf.sh <public dir> <page path> <out.pdf>"
public=${1:?$usage}
page=${2:?$usage}
out=${3:?$usage}
min_bytes=50000

[ -f "$public/${page%/}/index.html" ] || { echo "error: $public/$page not found; build the site first" >&2; exit 1; }

# CHROME_BIN is set on GitHub's ubuntu runners (/usr/bin/google-chrome).
browser=${CHROME_BIN:-}
if [ -z "$browser" ]; then
  for b in chromium google-chrome google-chrome-stable chromium-browser; do
    if command -v "$b" >/dev/null 2>&1; then browser=$b; break; fi
  done
fi
[ -n "$browser" ] || { echo "error: no chromium or google-chrome on PATH" >&2; exit 1; }

port=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])')
python3 -m http.server "$port" --bind 127.0.0.1 --directory "$public" >/dev/null 2>&1 &
server=$!
profile=$(mktemp -d)
trap 'kill "$server" 2>/dev/null || true; rm -rf "$profile"' EXIT

url="http://127.0.0.1:$port/${page#/}"
for _ in $(seq 50); do
  if python3 -c "import urllib.request,sys; urllib.request.urlopen(sys.argv[1], timeout=1)" "$url" 2>/dev/null; then break; fi
  sleep 0.1
done

mkdir -p "$(dirname "$out")"
rm -f "$out"
echo "printing $url with $("$browser" --version 2>/dev/null || echo "$browser")"
# --virtual-time-budget lets the web fonts finish loading before printing.
# --no-sandbox: the runner's Chromium can't use the user-namespace sandbox
# under Ubuntu 24.04's AppArmor policy; the page is our own build.
"$browser" --headless --disable-gpu --no-sandbox --no-first-run \
  --user-data-dir="$profile" \
  --no-pdf-header-footer --virtual-time-budget=15000 \
  --run-all-compositor-stages-before-draw \
  --print-to-pdf="$out" "$url" 2>/dev/null || true

if [ ! -f "$out" ] || [ "$(head -c 5 "$out")" != "%PDF-" ]; then
  echo "error: $out was not written" >&2; exit 1
fi
size=$(wc -c < "$out")
if [ "$size" -lt "$min_bytes" ]; then
  echo "error: $out is only $size bytes; the print went wrong" >&2; exit 1
fi
echo "wrote $out ($size bytes)"
