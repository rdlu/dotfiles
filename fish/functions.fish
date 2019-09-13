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

  set PROJ_NAME (basename (pwd) | sed "s/.//" )
  git remote rm origin 2> /dev/null
  git remote rm github 2> /dev/null
  git remote rm gitlab 2> /dev/null
  echo "Setting multiple git origin on "$GIT_ORG"/"$PROJ_NAME
  git remote add origin ssh://git@gitlab.com/$GIT_ORG/$PROJ_NAME.git
  git remote set-url origin --add ssh://git@github.com/$GIT_ORG/$PROJ_NAME.git
  # git remote set-url origin --add https://bitbucket.org/$GIT_USER_NAME/(basename (pwd)).git
  git remote add gitlab ssh://git@gitlab.com/$GIT_ORG/$PROJ_NAME.git
  git remote add github ssh://git@github.com/$GIT_ORG/$PROJ_NAME.git
  # git remote add bitbucket https://bitbucket.org/$GIT_USER_NAME/(basename (pwd)).git
end