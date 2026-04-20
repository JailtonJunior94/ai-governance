#!/usr/bin/env bash
# Instala bats-core localmente em tests/lib/bats-core se nao estiver disponivel.
# Uso: bash tests/lib/install-bats.sh
# Apos execucao, bats fica em tests/lib/bats-core/bin/bats

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BATS_DIR="$SCRIPT_DIR/bats-core"
BATS_VERSION="1.11.1"

if command -v bats >/dev/null 2>&1; then
  exit 0
fi

if [[ -x "$BATS_DIR/bin/bats" ]]; then
  exit 0
fi

echo "Instalando bats-core v${BATS_VERSION}..."

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

curl -sL "https://github.com/bats-core/bats-core/archive/refs/tags/v${BATS_VERSION}.tar.gz" \
  -o "$tmpdir/bats.tar.gz"

tar -xzf "$tmpdir/bats.tar.gz" -C "$tmpdir"
rm -rf "$BATS_DIR"
mv "$tmpdir/bats-core-${BATS_VERSION}" "$BATS_DIR"

echo "bats-core instalado em $BATS_DIR/bin/bats"
