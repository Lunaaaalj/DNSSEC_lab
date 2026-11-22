#!/usr/bin/env bash
# Sign the tree bottom-up: beta -> signed -> root. Algorithm 13 (ECDSAP256SHA256), NSEC3 (no salt, 0 iterations).
# Keys live in lab/v2/<srv>/keys (private keys are git-ignored). Run as a normal user.
set -euo pipefail
cd "$(dirname "$0")/../v2"
ALG=ECDSAP256SHA256
NSEC3=(-3 - -H 0)               # RFC 9276: empty salt, 0 extra iterations

sign() {  # sign <srv> <zone> <source-file> <signed-file>
  local srv=$1 zone=$2 src=$3 out=$4
  ( cd "$srv"
    mkdir -p keys
    if ! ls keys/K"${zone%.}".+013+*.key >/dev/null 2>&1; then
      dnssec-keygen -q -K keys -a $ALG -f KSK -n ZONE "$zone"
      dnssec-keygen -q -K keys -a $ALG        -n ZONE "$zone"
    fi
    cp "zones/$src" "zones/$src.work"
    for ds in zones/dsset-*; do [ -e "$ds" ] && cat "$ds" >> "zones/$src.work"; done || true
    dnssec-signzone -S -K keys -d zones -o "$zone" "${NSEC3[@]}" -N unixtime \
      -f "zones/$out" "zones/$src.work"
    dnssec-verify -o "$zone" "zones/$out"
    rm -f "zones/$src.work"
  )
}

rm -f beta/zones/dsset-* signed/zones/dsset-* root/zones/dsset-*

sign beta   beta.signed db.beta.signed db.beta.signed.signed
cp beta/zones/dsset-beta.signed. signed/zones/            # DS for beta goes into its parent

sign signed signed      db.signed      db.signed.signed
cp signed/zones/dsset-signed. root/zones/                 # DS for signed goes into the root

sign root   .           db.root        db.root.signed

# Trust anchor for the validating resolver: DS of the root KSK (static-ds)
read -r _ _ _ tag alg dig hex < <(grep -m1 ' DS ' root/zones/dsset-.)
hex=${hex// /}
cat > recursive2/trust-anchor.conf <<TA
trust-anchors {
    . static-ds $tag $alg $dig "$hex";
};
TA
cp recursive2/trust-anchor.conf anchor.conf.delv
echo "== trust anchor =="; cat recursive2/trust-anchor.conf
