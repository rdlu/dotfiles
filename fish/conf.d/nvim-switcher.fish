function nvim-full
    env NVIM_APPNAME=nvim-full nvim $argv
end

function nv
    env NVIM_APPNAME=nvim-light nvim $argv
end

function nvims
    set items default nvim-lazy nvim-full
    set config (printf "%s\n" $items | fzf --prompt=" Neovim Config = " --height=~50% --layout=reverse --border --exit-0)
    if [ -z $config ]
        echo "Nothing selected"
        return 0
    else if [ $config = default ]
        set config ""
    end

    env NVIM_APPNAME=$config nvim $argv
end

bind \ce "nvims ."

abbr -a lvi "nvim-lazy ."
