#docker functions
function docker-bash --description "Execute bash in a running docker container"
  docker exec -it $argv[1] bash
end

function docker-sh --description "Execute default shell in a running docker container"
  if set -q argv[2]
    docker exec -it $argv[1] $argv[2]
  else
    docker exec -it $argv[1] /bin/sh
  end
end

function git-mirror-add
  if set -q argv[1]
    set GIT_ORG argv[1]
  else
    set GIT_ORG rdlu
  end

  set PROJ_NAME (basename (pwd) | sed "s/\.//" )
  git remote rm origin 2> /dev/null
  git remote rm github 2> /dev/null
  git remote rm gitlab 2> /dev/null
  fancy_print_title "Setting multiple git origin on "$GIT_ORG"/"$PROJ_NAME
  git remote add origin ssh://git@gitlab.com/$GIT_ORG/$PROJ_NAME.git
  git remote set-url origin --add ssh://git@github.com/$GIT_ORG/$PROJ_NAME.git
  # git remote set-url origin --add https://bitbucket.org/$GIT_USER_NAME/(basename (pwd)).git
  git remote add gitlab ssh://git@gitlab.com/$GIT_ORG/$PROJ_NAME.git
  git remote add github ssh://git@github.com/$GIT_ORG/$PROJ_NAME.git
  # git remote add bitbucket https://bitbucket.org/$GIT_USER_NAME/(basename (pwd)).git
end

function fancy_print_line
  set DEF_COLOR red
  if set -q argv[1]
    set_color $DEF_COLOR; printf $argv"\n"
  else
    fancy_print_line "It's just a function to echo in fancy way."
  end
end

function fancy_print_title
  set DEF_COLOR purple
  if set -q argv[1]
    set_color $DEF_COLOR; echo "--------------------------------------"
    fancy_print_line $argv
    set_color $DEF_COLOR; echo "--------------------------------------"
  else
    fancy_print_title "It's just a function to echo in fancy way."
  end
end

