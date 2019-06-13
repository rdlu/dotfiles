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

