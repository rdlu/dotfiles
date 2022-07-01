# Filesystem Navigation
abbr -a tf tail -f
abbr -a cpv 'sudo rsync --info=progress2 -avhW --no-compress'
abbr -a lsh ls -lah
abbr -a lsd 'ls -d */'
abbr -a mkdir mkdir -pv
alias path 'echo -e {$PATH\n}'
alias less 'less -FSRXc'
alias mv "mv -i" # "m" - never forget
alias cp "cp -i"
alias b "cd - >/dev/null && l" # b stands for back

if test (uname) != Darwin
    alias ls 'ls --color'
end

if type -q exa; and status is-interactive
    alias l "exa --time-style long-iso --color=auto -F"
    alias ll "l -Fahl"
    alias la "l -a"
else
    alias l "ls --color=auto -F"
    alias ll "l -Ahl"
    alias la "l -a"
end

if type -q bat; and status is-interactive
    alias cat bat
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

function j --description "Jump to directory using fasd for search"
    cd (fasd -d -e 'printf %s' "$argv")
end

function mcd --description "Creates a directory (recursively) and imediatelly changes to it"
    mkdir -p $argv && cd $argv
end
