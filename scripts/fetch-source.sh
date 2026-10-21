#!/bin/sh
# Clone the pinned base tree and apply the local patch series.
#
# usage: ./scripts/fetch-source.sh [--force]
#
# SRC_REPO / SRC_COMMIT / SRC_DIR can be overridden from the environment. --force deletes an
# existing checkout first (useful after editing patches).
set -eu
. "$(dirname -- "$0")/lib.sh"

force=0
[ "${1:-}" = "--force" ] && force=1

if [ "$force" = 1 ] && [ -d "$SRC_DIR" ]; then
    log "removing $SRC_DIR"
    rm -rf "$SRC_DIR"
fi

mkdir -p "$(dirname -- "$SRC_DIR")"

if [ ! -d "$SRC_DIR/.git" ]; then
    log "cloning $SRC_REPO"
    # Blobless clone keeps the first fetch small; the checkout still needs the full tree.
    git clone --filter=blob:none --no-checkout "$SRC_REPO" "$SRC_DIR"
fi

log "pinning to $SRC_COMMIT"
git -C "$SRC_DIR" fetch --depth 1 origin "$SRC_COMMIT" 2>/dev/null ||
    git -C "$SRC_DIR" fetch origin
git -C "$SRC_DIR" checkout --detach "$SRC_COMMIT" >/dev/null

head=$(git -C "$SRC_DIR" rev-parse HEAD)
[ "$head" = "$SRC_COMMIT" ] || die "checkout is $head, expected $SRC_COMMIT"

if [ -d "$SRC_DIR/.git/rebase-merge" ] || [ -d "$SRC_DIR/.git/rebase-apply" ]; then
    die "$SRC_DIR has an unfinished rebase; use --force"
fi

# Reset tracked files so repeated runs apply the same series to the same base.
git -C "$SRC_DIR" reset --hard "$SRC_COMMIT" >/dev/null
git -C "$SRC_DIR" clean -fd >/dev/null

count=0
for patch in "$ROOT"/patches/*.patch; do
    [ -f "$patch" ] || continue
    log "applying $(basename "$patch")"
    git -C "$SRC_DIR" apply --check "$patch" ||
        die "$(basename "$patch") does not apply to $SRC_COMMIT"
    git -C "$SRC_DIR" apply "$patch"
    count=$((count + 1))
done
log "applied $count local patch(es)"

mkdir -p "$ROOT/build"
{
    printf 'base_repo=%s\n' "$SRC_REPO"
    printf 'base_commit=%s\n' "$SRC_COMMIT"
    printf 'mesa_version=%s\n' "$(cat "$SRC_DIR/VERSION" 2>/dev/null || echo unknown)"
    printf 'patches=%s\n' "$count"
    printf 'fetched=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$ROOT/build/source-info.txt"

log "source ready: $SRC_DIR"
