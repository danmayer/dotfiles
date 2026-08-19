mkcd() {
  mkdir -p -- "$1" && cd -- "$1"
}

# Re-syncs private repos (see private-repos.sh / README.md "Private repos")
# at most once per calendar day, in the background, so a persistent machine
# (unlike Codespaces/Ona, never "re-provisioned") still picks up changes
# without a manual ./install.sh re-run -- and a normal terminal open never
# blocks on git/network to do it.
_dotfiles_sync_private_repos() {
  local marker="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles-private-repos-synced"
  local today
  today="$(date +%Y-%m-%d)"

  if [ -f "$marker" ] && [ "$(cat "$marker" 2>/dev/null)" = "$today" ]; then
    return 0
  fi

  mkdir -p "$(dirname "$marker")"
  ( "$DOTFILES_DIR/private-repos.sh" >/dev/null 2>&1 && printf '%s' "$today" > "$marker" ) &
  disown
}
