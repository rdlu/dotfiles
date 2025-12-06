# Filesystem Navigation
abbr -a tf tail -f
abbr -a cpv 'sudo rsync --info=progress2 -avhW --no-compress'
abbr -a lsh ls -lah
abbr -a lsdir 'ls -d */'
abbr -a lsw 'ls -lah -d'
abbr -a mkdir mkdir -pv
alias path 'echo -e {$PATH\n}'
alias less 'less -FSRXc'
alias mv "mv -i" # "m" - never forget
alias cp "cp -i"
alias b "cd - >/dev/null && l" # b stands for back
bind alt-f yazi

if test (uname) != Darwin
    alias ls 'ls --color'
end

if type -q eza; and status is-interactive
    alias ls "eza -al --time-style long-iso --color=auto --group-directories-first --icons"
    alias la 'eza -a --color=always --group-directories-first --icons'  # all files and dirs
    alias ll 'eza -l --color=always --group-directories-first --icons'  # long format
    alias lt 'eza -aT --color=always --group-directories-first --icons' # tree listing
    alias l. "eza -a | grep -e '^\.'"                                     # show only dotfiles
else
    alias l "ls --color=auto -F"
    alias ll "l -Ahl"
    alias la "l -a"
end

if type -q bat; and status is-interactive
    alias cat bat
end
if type -q batcat; and status is-interactive
    alias cat batcat
end

if type -q zoxide; and status is-interactive
    zoxide init fish | source
end

if type -q scooter
    abbr -a find-tui scooter
end

# cd aliases
function ..
    cd ..
end
function cd.
    cd ..
end
function cd..
    cd ../..
end
function cd...
    cd ../../..
end
function cd....
    cd ../../../..
end

function mcd --description "Creates a directory (recursively) and imediatelly changes to it"
    mkdir -p $argv && cd $argv
end
