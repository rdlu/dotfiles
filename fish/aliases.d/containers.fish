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