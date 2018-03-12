# abbreviations
abbr -a gps git push
abbr -a gpl git pull
abbr -a gc git commit -a
abbr -a gst git status
abbr -a tf tail -f
abbr -a lsh ls -lah

abbr -a pacman sudo pacman
abbr -a systart sudo systemctl start
abbr -a systatus sudo systemctl status
abbr -a systop sudo systemctl stop

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