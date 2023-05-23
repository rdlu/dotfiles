# Docker Management
alias docker 'sudo docker'
abbr -a dkc docker compose
abbr -a dkc-logs 'docker compose logs -f'
abbr -a dkcx 'docker compose exec'
abbr -a dkcs 'docker compose start'
abbr -a dkc-start 'docker compose start'
abbr -a dkc-stop 'docker compose stop'
abbr -a dkcup 'docker compose up -d'
abbr -a dkcdn 'docker compose down'
abbr -a dkcsu 'sudo systemctl start docker && docker compose up -d'

# Docker functions
function dkcx --description 'Executes $PROGRAM in $MACHINE'
    docker compose exec $argv[2] $argv[1]
end
for shell in bash sh fish zsh
    abbr -a dkcx-$shell dkcx $shell
end
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
