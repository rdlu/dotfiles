# fzf command-line *insert* pickers — house-grown, no plugin required.
#
# Pattern: one reusable core (_pick) + thin per-source pickers bound to keys.
# Each fuzzy-finds from a source command and inserts the selection at the cursor
# (replacing the current token), with a content-aware preview (fzf-preview) and
# the shared tokyonight theme ($FZF_DEFAULT_OPTS, from fzf-theme.fish). Inside
# tmux the picker floats as a centered popup; otherwise it's an inline --height.
#
# Keys avoid clashes with: atuin ^R + ?, thefuck ^F/escesc, nvim-switcher ^E,
# yazi alt-f, ^H backward-kill-word. (Mirror of the old fzf.fish key map.)
#
# Core: _pick [--multi] [--first-field] [--prompt=P] [--preview=CMD]
#             [--preview-window=SPEC] -- SOURCE...
#   SOURCE is a command (+args, no pipes — wrap a pipeline in a function and
#   pass that) printing one item per line; CMD is a preview template using {}.
#   --first-field keeps only the first whitespace field of each line (SHA, PID).
function _pick
    argparse multi first-field 'prompt=' 'preview=' 'preview-window=' -- $argv
    or return

    # --tmux: float as a centered popup inside tmux; harmlessly ignored outside.
    set -l fzf_args --ansi --tmux center,80%,70%
    set -q _flag_multi; and set -a fzf_args --multi
    set -q _flag_prompt; and set -a fzf_args --prompt "$_flag_prompt"
    if set -q _flag_preview
        set -l pw 'right:60%:wrap'
        set -q _flag_preview_window; and set pw "$_flag_preview_window"
        set -a fzf_args --preview "$_flag_preview" --preview-window "$pw"
    end

    # seed the query with the token under the cursor
    set -l token (commandline --current-token)
    test -n "$token"; and set -a fzf_args --query "$token"

    set -l picked ($argv | fzf $fzf_args)
    test -z "$picked"; and begin
        commandline --function repaint
        return
    end

    if set -q _flag_first_field
        set -l fields
        for line in $picked
            set -a fields (string split -m1 -- ' ' (string trim -- $line))[1]
        end
        set picked $fields
    end

    commandline --replace --current-token -- (string join ' ' -- $picked)
    commandline --insert ' '
    commandline --function repaint
end

# helper source: changed files as bare paths (strip the porcelain XY column)
function _pick_src_git_status
    git -c core.quotepath=false status --porcelain=v1 --no-renames \
        | string replace -r '^...' ''
end

# --- pickers (keys flow into the generated shell cheatsheet) -----------------

# Ctrl-T : files under cwd -> insert path(s)            [content-aware preview]
function _pick_files
    command -q fd; or return
    _pick --multi --prompt 'file> ' --preview 'fzf-preview {}' \
        -- fd --type f --hidden --exclude .git
end
bind ctrl-t _pick_files

# Ctrl-Alt-D : directories under cwd -> insert path     [eza tree preview]
function _pick_dirs
    command -q fd; or return
    _pick --prompt 'dir> ' --preview 'fzf-preview {}' \
        -- fd --type d --hidden --exclude .git
end
bind ctrl-alt-d _pick_dirs

# Ctrl-Alt-G : pacman repo packages -> insert name(s)   [pacman -Si preview]
function _pick_pacman
    command -q pacman; or return
    _pick --multi --prompt 'pacman> ' \
        --preview 'pacman -Si {} 2>/dev/null || paru -Si {} 2>/dev/null' \
        -- pacman -Slq
end
bind ctrl-alt-g _pick_pacman

# Ctrl-Alt-L : git commits -> insert SHA                [git show preview]
function _pick_git_log
    git rev-parse --is-inside-work-tree >/dev/null 2>&1; or return
    _pick --first-field --prompt 'commit> ' \
        --preview 'git show --color=always {1}' \
        -- git log --format='%h %cs %s'
end
bind ctrl-alt-l _pick_git_log

# Ctrl-Alt-S : changed files -> insert path(s)          [git diff preview]
function _pick_git_status
    git rev-parse --is-inside-work-tree >/dev/null 2>&1; or return
    _pick --multi --prompt 'changed> ' \
        --preview 'git diff HEAD --color=always -- {}' \
        -- _pick_src_git_status
end
bind ctrl-alt-s _pick_git_status

# Ctrl-Alt-P : processes -> insert PID                  [ps detail preview]
function _pick_procs
    _pick --first-field --prompt 'process> ' \
        --preview 'ps -p {1} -o pid,ppid,user,stat,etime,args --no-headers' \
        -- ps --no-headers -eo pid,user,%cpu,%mem,comm --sort=-%cpu
end
bind ctrl-alt-p _pick_procs

# Ctrl-V : shell variables -> insert name              [scope + value preview]
function _pick_src_vars --argument-names dump
    # bare names from the `$NAME:` header lines of a `set --show` dump
    grep -oE '^\$[A-Za-z_][A-Za-z0-9_]*:' $dump | string trim --chars '$:' \
        | string match -rv '^__pvd$' | sort -u
end
function _pick_vars
    set -l __pvd (mktemp -t fzf-vars.XXXXXX)
    set --show >$__pvd 2>/dev/null
    _pick --prompt 'variable> ' --preview "fzf-var-preview {} $__pvd" \
        -- _pick_src_vars $__pvd
    command rm -f $__pvd
end
bind ctrl-v _pick_vars
