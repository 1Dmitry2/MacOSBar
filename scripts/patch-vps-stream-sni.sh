#!/bin/bash
# Add mactools.duckdns.org → 127.0.0.1:8445 to nginx stream SNI map (idempotent).
set -euo pipefail
MAP=/etc/nginx/stream.d/mywave-sni-mux.conf
if [[ ! -f "$MAP" ]]; then
  echo "Missing $MAP — set up stream mux manually." >&2
  exit 1
fi
if grep -q 'mactools\.duckdns\.org' "$MAP"; then
  exit 0
fi
tmp="$(mktemp)"
awk '
/mywaveplayer\.duckdns\.org[[:space:]]+127\.0\.0\.1:8443;/ && !added {
  print
  print "    mactools.duckdns.org           127.0.0.1:8445;"
  added=1
  next
}
{ print }
' "$MAP" >"$tmp"
mv "$tmp" "$MAP"
