# abbreviations
abbr -a gps git push
abbr -a gpl git pull
abbr -a gc git commit -a
abbr -a gst git status
abbr -a tf tail -f
abbr -a lsh ls -lah

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