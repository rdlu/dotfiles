# Terminal management
abbr -a mux tmux new -A -s mux0 fish
abbr -a mux1 tmux new -A -s mux1 fish

# Graphics
alias nvrun 'set -lx __NV_PRIME_RENDER_OFFLOAD 1; set -lx __GLX_VENDOR_LIBRARY_NAME nvidia;'

abbr -a nvidia-disable 'sudo rm /etc/X11/xorg.conf.d/20-nvidia-primary.conf; sudo cp ~/.dotfiles/nvidia-x11/20-nvidia-prime.conf /etc/X11/xorg.conf.d/20-nvidia-prime.conf;'
abbr -a nvidia-enable 'sudo rm /etc/X11/xorg.conf.d/20-nvidia-prime.conf; sudo cp ~/.dotfiles/nvidia-x11/20-nvidia-primary.conf /etc/X11/xorg.conf.d/20-nvidia-primary.conf;'

alias f_echo fancy_print_line

function mans --description "Searches in MAN \$arg1 for \$arg2"
  man $argv[1] | grep -iC2 --color=always $argv[2] | less -FSRXc
end

function nvrun2
  begin
    set -lx __NV_PRIME_RENDER_OFFLOAD 1
    set -lx __GLX_VENDOR_LIBRARY_NAME nvidia
    $argv
  end
end

for snippet in {$HOME}/.dotfiles/fish/aliases.d/*
  source $snippet
end