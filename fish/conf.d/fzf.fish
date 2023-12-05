# fzf aliases
# requires fzf.fish
alias fsd _fzf_search_directory
alias fsgl _fzf_search_git_log
alias fsp _fzf_search_processes
set fzf_preview_dir_cmd eza --all --color=always --time-style long-iso
set fzf_fd_opts --hidden --exclude=.git
set fzf_diff_highlighter delta --paging=never --width=20
set fzf_directory_opts "--bind=ctrl-d:reload(fd --type directory),ctrl-f:reload(fd --type file)"
