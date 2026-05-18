#!/usr/bin/env nix-shell
#!nix-shell -i bash -p coreutils curl jq nix

set -euo pipefail

tag="${1:-latest}"

get_url() {
  jq -r '
    first(
      .assets[]?
      | select(.browser_download_url | test(".*haqq_.*_(?i)linux_(amd64|x86_64).*"))
      | .browser_download_url
    ) // ""
  ' <<<"$1"
}

get_hash() {
  local type="sha256"
  nix-hash --to-sri --type "$type" \
    "$(nix-prefetch-url --type "$type" "$1")"
}

if [ "$tag" = "latest" ]; then
  api="https://api.github.com/repos/haqq-network/haqq/releases/latest"
else
  api="https://api.github.com/repos/haqq-network/haqq/releases/tags/$tag"
fi

obj="$(curl --fail -s ${GITHUB_TOKEN:+-u ":$GITHUB_TOKEN"} "$api")"

version="$(jq -r '.tag_name' <<<"$obj" | sed 's/^v//')"
url="$(get_url "$obj")"

if [ -z "$url" ]; then
  echo "error: no linux amd64 asset for v$version" >&2
  exit 1
fi

hash="$(get_hash "$url")"

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
out="$dir/versions.json"

entry="$(jq -nc \
  --arg version "$version" \
  --arg url "$url" \
  --arg hash "$hash" \
  '{ ($version): { url: $url, hash: $hash } }')"

if [ -f "$out" ]; then
  jq --slurp 'add' "$out" <(echo "$entry") > "$out.tmp" && mv "$out.tmp" "$out"
else
  echo "$entry" | jq . > "$out"
fi

echo "updated: v$version" >&2
