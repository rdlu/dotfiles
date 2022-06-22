# Git related aliases
abbr -a gf git fetch --all
abbr -a gps git push
abbr -a gpsa 'git pushall'
abbr -a gpsu 'git push -u origin (git branch --show-current)'
abbr -a gpl git pull --all
abbr -a gc git commit -a
abbr -a gcm git commit -am
abbr -a gsw 'git switch'
abbr -a gst git status
abbr -a git-rename-main 'git branch -m master main; git push -u origin main'
abbr -a gck 'git checkout'
abbr -a gck-b 'git checkout -b'
abbr -a gck-clean 'git-checkout-clean'
abbr -a gck-m 'git-checkout-pull master'
abbr -a git-set-upstream 'git push --set-upstream origin (git branch --show-current)'
abbr -a git-undo-last 'git reset --soft HEAD~1'
abbr -a gdf 'git diff'
abbr -a gds 'git diff --staged'
abbr -a glg 'git log --all --oneline --graph --decorate'

function git-checkout-clean --description 'Checkout a clean branch after deleting the local one'
    git branch -D $argv[1]
    git-checkout-pull master
    git-checkout-pull $argv[1]
end

function git-checkout-pull --description 'Checkout and Pull Branch'
    git checkout $argv[1]
    git pull --all
end