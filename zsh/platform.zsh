# The one place OS/environment-specific branches live.

case "$(uname -s)" in
  Darwin)
    if [ -d /opt/homebrew/bin ]; then
      export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
    elif [ -d /usr/local/bin ]; then
      export PATH="/usr/local/bin:$PATH"
    fi
    ;;
esac

if [ -n "$WSL_DISTRO_NAME" ]; then
  # pbcopy/pbpaste-style clipboard interop with the Windows host
  if command -v clip.exe >/dev/null 2>&1; then
    alias pbcopy='clip.exe'
    alias pbpaste='powershell.exe -NoProfile -Command Get-Clipboard'
  fi
fi

if [ -n "$CODESPACES" ]; then
  # Nothing Codespaces-specific needed yet; kept as the deliberate landing
  # spot for it rather than scattering $CODESPACES checks elsewhere.
  :
fi
