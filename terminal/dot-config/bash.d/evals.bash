if command -v starship &>/dev/null; then
	eval "$(starship init bash)"
else
	echo "Starship is not installed. You can install it from https://starship.rs/"
fi

if command -v mise &>/dev/null; then
	eval "$(mise activate bash)"
fi

if command -v atuin &>/dev/null; then
	eval "$(atuin init bash --disable-up-arrow)"
fi

if [ -f "$HOME/.cargo/env" ]; then
	source "$HOME/.cargo/env"
fi

if command -v direnv &>/dev/null; then
	eval "$(direnv hook bash)"
fi

[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

if [[ "$START_TMUX" && ! "$TMUX" && -t 0 && ! "$INSIDE_EDITOR" ]]; then
	tmux new -A -s mux0 fish
fi
