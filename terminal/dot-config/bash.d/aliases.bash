alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

export LS_OPTIONS='--color=auto'
eval "$(dircolors)"
alias ls='ls $LS_OPTIONS'
alias lsh='ls -lah $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -l'
alias l='ls $LS_OPTIONS -lA'

# Terminal management
alias mux='tmux new-session -A -s mux0 fish'
alias mux1='tmux new-session -A -s mux1 fish'
