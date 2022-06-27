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
abbr -a gck-clean git-checkout-clean
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

function git-mirror-add --description "[repo name][org name] Replaces this repo origin with both Github and Gitlab"
    if set -q argv[2]
        set GIT_ORG argv[2]
    else
        set GIT_ORG rdlu
    end

    if set -q argv[2]
        set PROJ_NAME argv[2]
    else
        set PROJ_NAME (basename (pwd) | sed "s/\.//" )
    end

    git remote rm origin 2>/dev/null
    git remote rm github 2>/dev/null
    git remote rm gitlab 2>/dev/null
    fancy_print_title "Setting multiple git origin on "$GIT_ORG"/"$PROJ_NAME
    git remote add origin ssh://git@gitlab.com/$GIT_ORG/$PROJ_NAME.git
    git remote set-url origin --add ssh://git@github.com/$GIT_ORG/$PROJ_NAME.git
    # git remote set-url origin --add https://bitbucket.org/$GIT_USER_NAME/(basename (pwd)).git
    git remote add gitlab ssh://git@gitlab.com/$GIT_ORG/$PROJ_NAME.git
    git remote add github ssh://git@github.com/$GIT_ORG/$PROJ_NAME.git
    # git remote add bitbucket https://bitbucket.org/$GIT_USER_NAME/(basename (pwd)).git
end

function github-latest-release --description "Download the latest release from an Github repo"
    if set -q argv[1]
        curl -sL https://api.github.com/repos/$argv[1]/releases/latest | jq -r '.assets[].browser_download_url' | xargs -n 1 curl -O -L -C -
    else
        fancy_print_line "Format: github-latest-release <USER>/<REPO>. Download the latest release from an Github repo"
    end
end
