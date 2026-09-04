#!/usr/bin/env bash
# Run automatically by Ona on every environment start (Ona's own naming
# convention for this hook -- unrelated to install.sh, which Codespaces/Ona
# instead run once at creation time).
#
# Ona's EFS network directory (mounted at $EFS_MOUNT_POINT, set via this
# machine's Ona secrets) is shared across every Ona environment for this
# user. This script symlinks a short list of stateful, per-user
# directories/files into it so they survive across environments: Claude
# Code and Codex session state, Cursor's server state, and shell history.
#
# Deliberately narrow scope: this repo's Non-goals (see README.md, "Not AI
# tool config") already rule out versioning AI tool config in this repo.
# This script doesn't change that -- it only relocates existing runtime
# state onto a persistent volume, it never adds, tracks, or manages the
# *content* of any of these directories.
#
# Idempotent and non-destructive. Unlike a naive "delete then symlink"
# approach, an entry already correctly linked is left alone, and the first
# time a segment is linked, any real file/dir already at that path is
# moved (not deleted) into EFS so nothing is lost. No-ops entirely if
# EFS_MOUNT_POINT isn't set -- e.g. on macOS, WSL, Codespaces, or an Ona
# box not using the network directory.

set -euo pipefail

if [ -z "${EFS_MOUNT_POINT:-}" ]; then
  exit 0
fi

log() {
  printf '%s\n' "$*"
}

mkdir -p "$EFS_MOUNT_POINT"

link_to_efs() {
  segment="$1"
  home_path="$HOME/$segment"
  efs_path="$EFS_MOUNT_POINT/$segment"

  if [ -L "$home_path" ] && [ "$(readlink "$home_path")" = "$efs_path" ]; then
    return 0
  fi

  if [ ! -e "$efs_path" ] && [ -e "$home_path" ] && [ ! -L "$home_path" ]; then
    mkdir -p "$(dirname "$efs_path")"
    mv "$home_path" "$efs_path"
    log "Moved existing $home_path -> $efs_path"
  elif [ -e "$home_path" ] || [ -L "$home_path" ]; then
    rm -rf "$home_path"
  fi

  mkdir -p "$(dirname "$home_path")"
  ln -s "$efs_path" "$home_path"
  log "Linked $home_path -> $efs_path"
}

# Customize freely -- left off this list on purpose:
# - .zshrc / .zshenv / .zprofile: ~/.zshrc is install.sh's own untracked
#   stub (see README.md "zsh setup"). Symlinking it into EFS would fight
#   install.sh for ownership of that file on every re-run.
# - .oh-my-zsh: not used by this config (see README.md Goals -- plain zsh,
#   no framework).
for segment in .claude .claude.json .codex .cursor .cursor-server .zsh_history; do
  link_to_efs "$segment"
done

log "post-start-install.sh: EFS links up to date under $EFS_MOUNT_POINT"
