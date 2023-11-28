# Graphics
alias nvrun 'set -lx __NV_PRIME_RENDER_OFFLOAD 1; set -lx __GLX_VENDOR_LIBRARY_NAME nvidia;'

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
