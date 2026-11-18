#!/usr/bin/env bash
# ============================================================
# dump-partitions.sh  -  XIG02 (iris) full partition dump
#
# Same behavior as dump-partitions.bat, for bash environments.
#
# Prerequisites:
#   - Bootloader unlocked, recovery booted via "fastboot boot"
#     (NOT flashed), device visible from adb in recovery mode.
#
# Usage:
#   ./dump-partitions.sh [output_dir]   (default: ./dump)
#
# Behavior:
#   - Dumps every partition in /dev/block/by-name except
#     userdata (encrypted and huge).
#   - dd runs with conv=noerror,sync so a known unreadable
#     region (see research/ota-install-error.md) does not
#     stop the dump; bad blocks are zero-filled and dd's
#     stderr is kept per partition as <name>.dd.log.
#   - Records partition size, dumped file size and SHA256
#     into manifest.txt.
# ============================================================
set -u

OUT="${1:-./dump}"
mkdir -p "$OUT"
echo "Output: $OUT"

if ! adb get-state >/dev/null 2>&1; then
  echo "[ABORT] No adb device found. Boot the recovery first." >&2
  exit 1
fi

adb shell "ls /dev/block/by-name" | tr -d '\r' > "$OUT/by-name.txt" || {
  echo "[ABORT] Cannot list /dev/block/by-name." >&2
  exit 1
}
[ -s "$OUT/by-name.txt" ] || {
  echo "[ABORT] /dev/block/by-name looks empty." >&2
  exit 1
}

adb shell dmesg > "$OUT/dmesg-before.txt" 2>/dev/null

MANIFEST="$OUT/manifest.txt"
{
  echo "# XIG02 (iris) partition dump"
  echo "# format: name partition_bytes file_bytes sha256"
} > "$MANIFEST"

while IFS= read -r P; do
  P="$(echo "$P" | tr -d ' \r')"
  [ -n "$P" ] || continue
  if [ "$P" = "userdata" ]; then
    echo "Skipping userdata (encrypted, not dumped)"
    continue
  fi

  DEV="/dev/block/by-name/$P"
  PSIZE="$(adb shell "blockdev --getsize64 $DEV" 2>/dev/null | tr -d ' \r')"
  [ -n "$PSIZE" ] || PSIZE="unknown"

  echo "Dumping $P (partition bytes: $PSIZE) ..."
  if ! adb exec-out dd if="$DEV" bs=4096 conv=noerror,sync \
       > "$OUT/$P.img" 2> "$OUT/$P.dd.log"; then
    echo "[WARN] dd returned an error for $P - see $P.dd.log"
  fi

  FSIZE="$(stat -c %s "$OUT/$P.img" 2>/dev/null || stat -f %z "$OUT/$P.img")"
  if [ "$FSIZE" = "0" ] && [ "$PSIZE" != "0" ]; then
    echo "[ABORT] $P.img is empty. exec-out may not work in this recovery. Stop and use the fallback method." >&2
    exit 1
  fi

  HASH="$(sha256sum "$OUT/$P.img" | awk '{print $1}')"
  echo "$P $PSIZE $FSIZE $HASH" >> "$MANIFEST"
  echo "  file bytes: $FSIZE  sha256: $HASH"
done < "$OUT/by-name.txt"

adb shell dmesg > "$OUT/dmesg-after.txt" 2>/dev/null

echo
echo "Done. Check manifest.txt and any *.dd.log with errors."
echo "Copy the whole folder to a second location and verify hashes."
