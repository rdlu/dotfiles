# Git related
abbr -a gf git fetch --all
abbr -a gps git push
abbr -a gpsa 'git pushall'
abbr -a gpsu 'git push -u origin (git branch --show-current)'
abbr -a gpl git pull --all
abbr -a gc git commit -a
abbr -a gcm git commit -am
abbr -a gsw 'git switch'
abbr -a gst git status
abbr -a git-rename-main 'git branch -m master main; git push -u origin main'
abbr -a gck 'git checkout'
abbr -a gck-b 'git checkout -b'
abbr -a gck-clean 'git-checkout-clean'
abbr -a gck-m 'git-checkout-pull master'
abbr -a git-set-upstream 'git push --set-upstream origin (git branch --show-current)'
abbr -a git-undo-last 'git reset --soft HEAD~1'
abbr -a gdf 'git diff'
abbr -a gds 'git diff --staged'
abbr -a glg 'git log --all --oneline --graph --decorate'


# Filesystem
abbr -a tf tail -f
abbr -a cpv 'sudo rsync --info=progress2 -avhW --no-compress'
abbr -a lsh ls -lah
abbr -a lsd 'ls -d */'
abbr -a mkdir mkdir -pv
alias path 'echo -e {$PATH\n}'
alias less 'less -FSRXc'
alias mv "mv -i"  # "m" - never forget
alias cp "cp -i"
alias b "cd - >/dev/null && l" # b stands for back

if test (uname) != Darwin
  alias ls 'ls --color'
end

if type -q exa
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

# Terminal management
abbr -a mux tmux new -A -s mux0 fish
abbr -a mux1 tmux new -A -s mux1 fish

# Node.js
abbr -a npmkill find . -name 'node_modules' -type d -prune -print -exec rm -rf '{}' +
abbr -a rm-npm-modules find . -name 'node_modules' -type d -prune -print -exec rm -rf '{}' +

# System management
abbr -a pacman sudo pacman
abbr -a systart sudo systemctl start
abbr -a systatus sudo systemctl status
abbr -a sysnable sudo systemctl enable --now
abbr -a systop sudo systemctl stop

# Networking
abbr -a sockets-list 'sudo /usr/sbin/lsof -i -P'             # lsock:        Display open sockets
abbr -a sockets-list-udp 'sudo /usr/sbin/lsof -nP | grep UDP'   # lsockU:       Display only open UDP sockets
abbr -a sockets-list-tcp 'sudo /usr/sbin/lsof -nP | grep TCP'   # lsockT:       Display only open TCP sockets
abbr -a sockets-list-listening 'sudo lsof -i | grep LISTEN'        # openPorts:    All listening connections
abbr -a myip 'dig +short myip.opendns.com @resolver1.opendns.com'    
abbr -a myip2 'dig TXT +short o-o.myaddr.l.google.com @ns1.google.com'
abbr -a gateway-ip-address 'ip route list | awk \' /^default/ {print $3}\''
abbr -a ping-gateway 'ping (ip route list | awk \' /^default/ {print $3}\')'

# Graphics
alias nvrun 'set -lx __NV_PRIME_RENDER_OFFLOAD 1; set -lx __GLX_VENDOR_LIBRARY_NAME nvidia;'

# Docker Management
alias docker 'doas docker'
abbr -a dkc docker compose
abbr -a dkc-logs 'docker compose logs -f'
abbr -a dkcx 'docker compose exec'
abbr -a dkcs 'docker compose start'
abbr -a dkc-start 'docker compose start'
abbr -a dkc-stop 'docker compose stop'
abbr -a dkcup 'docker compose up -d'
abbr -a dkcdn 'docker compose down'
function dkcx --description 'Executes $PROGRAM in $MACHINE'
  docker compose exec $argv[2] $argv[1]
end
for shell in bash sh fish zsh
  abbr -a dkcx-$shell dkcx $shell
end

# Python, Django, Poetry
abbr -a pyman 'python manage.py'
abbr -a poshe 'poetry shell'
abbr -a poadd 'poetry add --dev'
abbr -a poupd 'poetry update'
abbr -a poins 'poetry install'

# Ruby, Rails
abbr -a bex 'bundle exec'
abbr -a rac 'rails console'
abbr -a rsp 'bundle exec rspec'
abbr -a rspec 'bundle exec rspec'

# System Maintenance
abbr -a cache-sizes 'du -sh ~/.cache/* | sort -h'
abbr -a cache-delete-old-files 'find ~/.cache/ -type f -atime +100 -delete'
abbr -a logs-sizes 'journalctl --disk-usage'
abbr -a logs-previous-boot 'sudo journalctl -b-1'
abbr -a logs-delete-old-entries 'sudo journalctl --vacuum-size=50M; sudo journalctl --vacuum-time=2weeks'
abbr -a pacman-installed-packages 'pacman -Qentq'
abbr -a pacman-installed-foreign 'pacman -Qemtq'
abbr -a pacman-installed-opt-packs 'pacman -Qdq'
abbr -a open-current-dir 'xdg-open .'
abbr -a open 'xdg-open'

abbr -a nvidia-disable 'sudo rm /etc/X11/xorg.conf.d/20-nvidia-primary.conf; sudo cp ~/.dotfiles/nvidia-x11/20-nvidia-prime.conf /etc/X11/xorg.conf.d/20-nvidia-prime.conf;'
abbr -a nvidia-enable 'sudo rm /etc/X11/xorg.conf.d/20-nvidia-prime.conf; sudo cp ~/.dotfiles/nvidia-x11/20-nvidia-primary.conf /etc/X11/xorg.conf.d/20-nvidia-primary.conf;'

# Utils
abbr -a date-iso 'date -u +"%Y-%m-%dT%H:%M:%S%Z"'
abbr -a date-timestamp 'date +%s'

alias f_echo fancy_print_line

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

function mans --description "Searches in MAN \$arg1 for \$arg2"
  man $argv[1] | grep -iC2 --color=always $argv[2] | less -FSRXc
end

function myps
  ps $argv -u $USER -o pid,%cpu,%mem,start,time,bsdtime,command
end

function nvrun2
  begin
    set -lx __NV_PRIME_RENDER_OFFLOAD 1
    set -lx __GLX_VENDOR_LIBRARY_NAME nvidia
    $argv
  end
end

function git-checkout-clean --description 'Checkout a clean branch after deleting the local one'
  git branch -D $argv[1]
  git-checkout-pull master
  git-checkout-pull $argv[1]
end

function git-checkout-pull --description 'Checkout and Pull Branch'
  git checkout $argv[1]
  git pull --all
end