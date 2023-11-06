if command -v starship &> /dev/null; then
  eval "$(starship init bash)"
else
  echo "Starship is not installed. You can install it from https://starship.rs/"
fi

if command -v rtx &> /dev/null; then
  eval "$(rtx activate bash)"
fi

if [ -f "$HOME/.cargo/env" ]; then
  source "$HOME/.cargo/env"
fi

[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"
