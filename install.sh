#!/usr/bin/env bash
# Idempotent. Safe to re-run any time, including non-interactively (this is
# what GitHub Codespaces runs automatically after cloning this repo). See
# README.md for the reasoning behind each piece of this.
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
case "$(uname -s)" in
  Darwin) IS_MACOS=1 ;;
esac
if [ -n "${CODESPACES:-}" ]; then
  IS_CODESPACES=1
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

# --- shell: best-effort, never blocks the rest of the script ---

if [ "$IS_CODESPACES" -eq 0 ] && command -v chsh >/dev/null 2>&1 && command -v zsh >/dev/null 2>&1; then
  if [ "${SHELL:-}" != "$(command -v zsh)" ]; then
    chsh -s "$(command -v zsh)" >/dev/null 2>&1 || log "Skipping chsh (no permission, or already handled)"
  fi
fi

# --- Homebrew (macOS only, skipped entirely elsewhere) ---

if [ "$IS_MACOS" -eq 1 ] && [ "$IS_CODESPACES" -eq 0 ] && command -v brew >/dev/null 2>&1 && [ -f "$DOTFILES_DIR/Brewfile" ]; then
  brew bundle --file="$DOTFILES_DIR/Brewfile" || log "brew bundle failed, continuing"
fi

log "dotfiles install complete"
