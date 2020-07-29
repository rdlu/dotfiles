# abbreviations
abbr -a gf git fetch --all
abbr -a gps git push
abbr -a gpsa 'git pushall'
abbr -a gpl git pull --all
abbr -a gc git commit -a
abbr -a gcm git commit -am
abbr -a gsw 'git switch'
abbr -a cpv 'sudo rsync --info=progress2 -avhW --no-compress'
abbr -a gst git status
abbr -a tf tail -f
abbr -a lsh ls -lah
abbr -a lsd ls -d */

abbr -a pacman sudo pacman
abbr -a systart sudo systemctl start
abbr -a systatus sudo systemctl status
abbr -a sysnable sudo systemctl enable --now
abbr -a systop sudo systemctl stop
abbr -a mux tmux new -A -s mux0 fish
abbr -a mux1 tmux new -A -s mux1 fish
abbr -a mkdir mkdir -pv

abbr -a lsock 'sudo /usr/sbin/lsof -i -P'             # lsock:        Display open sockets
abbr -a lsockU 'sudo /usr/sbin/lsof -nP | grep UDP'   # lsockU:       Display only open UDP sockets
abbr -a lsockT 'sudo /usr/sbin/lsof -nP | grep TCP'   # lsockT:       Display only open TCP sockets
abbr -a openPorts 'sudo lsof -i | grep LISTEN'        # openPorts:    All listening connections
abbr -a myip 'dig +short myip.opendns.com @resolver1.opendns.com'    
abbr -a myip2 'dig TXT +short o-o.myaddr.l.google.com @ns1.google.com'
abbr -a gateway-ip-address 'ip route list | awk \' /^default/ {print $3}\''
abbr -a ping-gateway 'ping (ip route list | awk \' /^default/ {print $3}\')'

alias path 'echo -e {$PATH\n}'
alias less 'less -FSRXc'
alias nvrun 'set -lx __NV_PRIME_RENDER_OFFLOAD 1; set -lx __GLX_VENDOR_LIBRARY_NAME nvidia;'
alias ls 'ls --color'

# Python and Django
abbr -a pyman python manage.py 
abbr -a pyenv-shell 'pipenv shell'

# System Maintenance
abbr -a cache-sizes du -sh ~/.cache/* | sort -h
abbr -a cache-delete-old-files find ~/.cache/ -type f -atime +100 -delete
abbr -a logs-sizes journalctl --disk-usage
abbr -a logs-previous-boot 'sudo journalctl -b-1'
abbr -a logs-delete-old-entries 'sudo journalctl --vacuum-size=50M; sudo journalctl --vacuum-time=2weeks'
abbr -a pacman-installed-packages 'pacman -Qentq'
abbr -a pacman-installed-foreign 'pacman -Qemtq'
abbr -a pacman-installed-opt-packs 'pacman -Qdq'

abbr -a nvidia-disable 'sudo rm /etc/X11/xorg.conf.d/20-nvidia-primary.conf; sudo cp ~/.dotfiles/nvidia-x11/20-nvidia-prime.conf /etc/X11/xorg.conf.d/20-nvidia-prime.conf;'
abbr -a nvidia-enable 'sudo rm /etc/X11/xorg.conf.d/20-nvidia-prime.conf; sudo cp ~/.dotfiles/nvidia-x11/20-nvidia-primary.conf /etc/X11/xorg.conf.d/20-nvidia-primary.conf;'


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

function j
  cd (fasd -d -e 'printf %s' "$argv")
end

function mcd
  mkdir -p $argv && cd $argv
end

function mans
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
