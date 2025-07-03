#!/usr/bin/env nix-shell
#!nix-shell -i bash -p coreutils curl jq nix

set -euo pipefail

get_version() {
  jq -r '.tag_name' <<<"$1" |
    sed 's/^v//'
}

get_url() {
  jq -r '
    .assets[]? | select(
      .browser_download_url |
      test(".*haqq_.*_(?i)linux_(amd64|x86_64).*")
    ) | .browser_download_url
  ' <<<"$1"
}

get_hash() {
  local type="sha256"
  nix-hash \
    --to-sri \
    --type "$type" \
    "$(nix-prefetch-url --type "$type" "$1")"
}

api="https://api.github.com/repos/haqq-network/haqq/releases"
result="$(curl --fail -s ${GITHUB_TOKEN:+-u ":$GITHUB_TOKEN"} "$api")"

declare -a versions

while read -r obj; do
  version="$(get_version "$obj")"
  url="$(get_url "$obj")"
  hash="$(get_hash "$url")"

  versions+=(
    "$(
      jq -nc \
        --arg version "$version" \
        --arg url "$url" \
        --arg hash "$hash" \
        '{ $version: { url: $url, hash: $hash } }'
    )"
  )
done < <(jq -c '.[] | select(.prerelease | not)' <<<"$result")

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
jq --slurp 'add' <<<"${versions[*]}" >"$dir/versions.json"
