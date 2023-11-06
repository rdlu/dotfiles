abbr -a stgip 'set -lx TGT_IP 10.'
abbr -a nmaps 'nmap -sC -sV $TGT_IP'
abbr -a smbclis "smbclient -N -L \\\\\\\\$TGT_IP\\\\"
abbr -a smbclils "smbclient -N \\\\\\\\$TGT_IP\\\\folder"
