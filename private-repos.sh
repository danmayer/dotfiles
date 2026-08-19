#!/usr/bin/env bash
# Clones/pulls each repo listed in an untracked, machine-local
# ~/.dotfiles.private.sh (see README.md "Private repos"), then runs that
# repo's own bootstrap.sh if present.
#
# Called from two places:
#   - install.sh, during provisioning (Codespaces, Ona, a fresh machine)
#   - the zsh interactive hook (zsh/functions.zsh), on a throttled
#     once-per-day cadence, so a persistent machine (a Mac that's never
#     "re-provisioned") still picks up changes without a manual
#     ./install.sh re-run every time.
#
# Best-effort throughout (logs and continues rather than aborting) since the
# zsh hook runs this unattended, in the background, from an interactive
# shell -- a network hiccup here should never be visible as a shell error.
#
# Written for bash 3.2 (macOS's stock /bin/bash) — no associative arrays,
# no other 4.0+ features.

set -uo pipefail # no -e: best-effort, see above

log() {
  printf '%s\n' "$*"
}

PRIVATE_REPOS_FILE="$HOME/.dotfiles.private.sh"
PRIVATE_REPOS=()

if [ -f "$PRIVATE_REPOS_FILE" ]; then
  # shellcheck disable=SC1090
  source "$PRIVATE_REPOS_FILE"

  if [ "${#PRIVATE_REPOS[@]}" -gt 0 ]; then
    for entry in "${PRIVATE_REPOS[@]}"; do
      repo_url="${entry%%|*}"
      repo_dir="${entry#*|}"

      if [ -d "$repo_dir/.git" ]; then
        log "Updating private repo $repo_dir"
        git -C "$repo_dir" pull --rebase --quiet || log "Pull failed for $repo_dir, continuing"
      else
        log "Cloning private repo -> $repo_dir"
        git clone --quiet "$repo_url" "$repo_dir" || log "Clone failed for $repo_dir, continuing"
      fi

      if [ -x "$repo_dir/bootstrap.sh" ]; then
        log "Running $repo_dir/bootstrap.sh"
        "$repo_dir/bootstrap.sh" || log "$repo_dir/bootstrap.sh failed, continuing"
      fi
    done
  fi
fi
