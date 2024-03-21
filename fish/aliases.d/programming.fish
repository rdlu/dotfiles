# Ruby, Rails
abbr -a bex 'bundle exec'
abbr -a rac 'rails console'
abbr -a rsp 'bundle exec rspec'
abbr -a rspec 'bundle exec rspec'

# Python, Django, Poetry
abbr -a pyman 'python manage.py'
abbr -a poshe 'poetry shell'
abbr -a poadd 'poetry add --dev'
abbr -a poupd 'poetry update'
abbr -a poins 'poetry install'

# Elixir
abbr -a imix 'iex -S mix'
abbr -a mxt 'MIX_ENV=test mix test'
abbr -a phxs 'mix phx.server'
abbr -a phxis 'iex -S mix phx.server'

# Node.js
abbr -a npmkill find . -name node_modules -type d -prune -print -exec rm -rf '{}' +
abbr -a rm-npm-modules find . -name node_modules -type d -prune -print -exec rm -rf '{}' +


# Rust
abbr -a cgrn 'cargo run'
abbr -a cgcp 'cargo clippy'
abbr -a cgr 'cargo run'
abbr -a cgt 'cargo nextest r'
abbr -a cgb 'cargo build'

if type -q rtx
    abbr -a asdf rtx
end
