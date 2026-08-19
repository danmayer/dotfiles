#!/usr/bin/env bash
# Idempotent. Safe to re-run any time, including non-interactively (this is
# what GitHub Codespaces and Ona run automatically after cloning this repo).
# See README.md for the reasoning behind each piece of this.
#
# Written for bash 3.2 (macOS's stock /bin/bash) — no associative arrays,
# no other 4.0+ features.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
  printf '%s\n' "$*"
}

# --- platform detection ---

IS_MACOS=0
IS_CODESPACES=0
IS_ONA=0
case "$(uname -s)" in
  Darwin) IS_MACOS=1 ;;
esac
if [ -n "${CODESPACES:-}" ]; then
  IS_CODESPACES=1
fi
if [ "${IS_ON_ONA:-}" = "true" ]; then
  IS_ONA=1
fi

# --- plain symlinks ---

link_file() {
  src="$1"
  dest="$2"

  if [ -L "$dest" ]; then
    if [ "$(readlink "$dest")" = "$src" ]; then
      return 0
    fi
    rm -f "$dest"
  elif [ -e "$dest" ]; then
    log "Backing up existing $dest -> $dest.pre-dotfiles"
    mv "$dest" "$dest.pre-dotfiles"
  fi

  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  log "Linked $dest -> $src"
}

link_file "$DOTFILES_DIR/emacs/init.el" "$HOME/.emacs.d/init.el"

# --- ~/.zshrc: untracked stub, marker-delimited header only ---

ZSHRC_MARKER="# --- dotfiles: anything below this line is untouched by install.sh ---"

write_zshrc_stub() {
  target="$HOME/.zshrc"
  tmp="$(mktemp "${TMPDIR:-/tmp}/dotfiles-zshrc.XXXXXX")"

  {
    printf '%s\n' "# --- managed by dotfiles install.sh: do not edit above this line ---"
    printf 'export DOTFILES_DIR="%s"\n' "$DOTFILES_DIR"
    printf 'source "%s/zsh/zshrc"\n' "$DOTFILES_DIR"
    printf '%s\n' "$ZSHRC_MARKER"
  } > "$tmp"

  if [ -f "$target" ] && [ ! -L "$target" ]; then
    if grep -qF "$ZSHRC_MARKER" "$target"; then
      awk -v marker="$ZSHRC_MARKER" 'found{print} $0==marker{found=1}' "$target" >> "$tmp"
    else
      log "Preserving existing ~/.zshrc content below the dotfiles header"
      printf '\n' >> "$tmp"
      cat "$target" >> "$tmp"
    fi
  elif [ -L "$target" ]; then
    log "Backing up existing $target -> $target.pre-dotfiles"
    mv "$target" "$target.pre-dotfiles"
  fi

  mv "$tmp" "$target"
  log "Wrote $target stub"
}

write_zshrc_stub

# --- ~/.gitconfig: untracked, install.sh only ensures two lines exist ---

write_gitconfig_stub() {
  target="$HOME/.gitconfig"
  touch "$target"

  if grep -qF "path = $DOTFILES_DIR/git/gitconfig" "$target" 2>/dev/null; then
    return 0
  fi

  tmp="$(mktemp "${TMPDIR:-/tmp}/dotfiles-gitconfig.XXXXXX")"
  {
    printf '[include]\n'
    printf '    path = %s/git/gitconfig\n' "$DOTFILES_DIR"
    printf '[core]\n'
    printf '    excludesfile = %s/git/gitignore_global\n' "$DOTFILES_DIR"
    cat "$target"
  } > "$tmp"
  mv "$tmp" "$target"
  log "Added include/excludesfile lines to $target"
}

write_gitconfig_stub

# --- packages: install only what's actually missing, never touch what's
# --- already there. Runs before the chsh step below so a just-installed
# --- zsh is on PATH for that check.

run_privileged() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    log "No root and no sudo available, skipping: $*"
    return 1
  fi
}

# Homebrew (macOS). --no-upgrade: install anything from the Brewfile that's
# missing, but never silently upgrade something already installed — this
# config assumes the tools exist, it doesn't own their version.
if [ "$IS_MACOS" -eq 1 ] && command -v brew >/dev/null 2>&1 && [ -f "$DOTFILES_DIR/Brewfile" ]; then
  brew bundle --no-upgrade --file="$DOTFILES_DIR/Brewfile" || log "brew bundle failed, continuing"
fi

# apt (WSL, Codespaces, generic Linux). Same "only what's missing" rule —
# Codespaces images already ship git; only really needs to fetch anything
# on a fresh container when emacs isn't preinstalled.
if [ "$(uname -s)" = "Linux" ] && command -v apt-get >/dev/null 2>&1; then
  missing=""
  for pkg in git zsh emacs; do
    command -v "$pkg" >/dev/null 2>&1 || missing="$missing $pkg"
  done

  if [ -n "$missing" ]; then
    log "Installing missing packages via apt:$missing"
    export DEBIAN_FRONTEND=noninteractive
    run_privileged apt-get update -y </dev/null || log "apt-get update failed, continuing"
    # shellcheck disable=SC2086
    run_privileged apt-get install -y $missing </dev/null || log "apt-get install failed, continuing"
  else
    log "git, zsh, emacs already present, skipping apt"
  fi
fi

# --- shell: best-effort, never blocks the rest of the script ---

if [ "$IS_CODESPACES" -eq 0 ] && [ "$IS_ONA" -eq 0 ] && command -v chsh >/dev/null 2>&1 && command -v zsh >/dev/null 2>&1; then
  if [ "${SHELL:-}" != "$(command -v zsh)" ]; then
    chsh -s "$(command -v zsh)" </dev/null >/dev/null 2>&1 || log "Skipping chsh (no permission, or already handled)"
  fi
fi

# --- private repos: untracked, machine-specific, never committed here ---
# See README.md "Private repos" for the full contract, and private-repos.sh
# for the implementation (shared with the zsh interactive hook that keeps
# a persistent machine in sync without a manual re-run -- see zshrc setup).

"$DOTFILES_DIR/private-repos.sh" || log "private-repos.sh failed, continuing"

log "dotfiles install complete"
