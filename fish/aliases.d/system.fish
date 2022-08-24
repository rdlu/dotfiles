# Utils
abbr -a date-iso 'date -u +"%Y-%m-%dT%H:%M:%S%Z"'
abbr -a date-timestamp 'date +%s'

# System management
abbr -a pacman sudo pacman
abbr -a systart sudo systemctl start
abbr -a systatus sudo systemctl status
abbr -a sysnable sudo systemctl enable --now
abbr -a systop sudo systemctl stop

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
abbr -a open xdg-open

# Networking
abbr -a sockets-list 'sudo /usr/sbin/lsof -i -P' # lsock:        Display open sockets
abbr -a sockets-list-udp 'sudo /usr/sbin/lsof -nP | grep UDP' # lsockU:       Display only open UDP sockets
abbr -a sockets-list-tcp 'sudo /usr/sbin/lsof -nP | grep TCP' # lsockT:       Display only open TCP sockets
abbr -a sockets-list-listening 'sudo lsof -i | grep LISTEN' # openPorts:    All listening connections
abbr -a myip 'dig +short myip.opendns.com @resolver1.opendns.com'
abbr -a myip2 'dig TXT +short o-o.myaddr.l.google.com @ns1.google.com'
abbr -a gateway-ip-address 'ip route list | awk \' /^default/ {print $3}\''
abbr -a ping-gateway 'ping (ip route list | awk \' /^default/ {print $3}\')'


function myps
    ps $argv -u $USER -o pid,%cpu,%mem,start,time,bsdtime,command
end

abbr -a is-running-ps "ps ax | grep -q '[w]in-gpg-agent'"
