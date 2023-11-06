. "$HOME/.cargo/env"

if command -v starship &> /dev/null; then
  eval "$(starship init bash)"
else
  echo "Starship is not installed. You can install it from https://starship.rs/"
fi

if command -v rtx &> /dev/null; then
  eval "$(rtx activate bash)"
else
  echo "rtx is not installed or not in your PATH."
fi

if [ -f "$HOME/.cargo/env" ]; then
  source "$HOME/.cargo/env"
fi
