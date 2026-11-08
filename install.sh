#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
bundle="$root/build/linux/x64/release/bundle"

if [ ! -x "$bundle/opencode_usage" ]; then
  echo "build first: flutter build linux --release" >&2
  exit 1
fi

prefix=${PREFIX:-"$HOME/.local"}
libdir="$prefix/lib/opencode-usage"
bindir="$prefix/bin"
appdir="$prefix/share/applications"

rm -rf "$libdir"
mkdir -p "$libdir" "$bindir" "$appdir"
cp -a "$bundle/." "$libdir/"
ln -sf "$libdir/opencode_usage" "$bindir/opencode-usage"

sed "s|@EXEC@|$bindir/opencode-usage|" \
  "$root/packaging/opencode-usage.desktop" \
  >"$appdir/opencode-usage.desktop"

echo "installed $bindir/opencode-usage"
