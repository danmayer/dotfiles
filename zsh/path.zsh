# Platform-agnostic PATH additions. OS-specific PATH bits live in platform.zsh.

for dir in "$HOME/bin" "$HOME/.local/bin"; do
  if [ -d "$dir" ]; then
    case ":$PATH:" in
      *":$dir:"*) ;;
      *) PATH="$dir:$PATH" ;;
    esac
  fi
done
export PATH
