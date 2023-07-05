function nvim-lazy
    env NVIM_APPNAME=nvim-lazy nvim $argv
end

function nvim-astro
    env NVIM_APPNAME=nvim-astro nvim $argv
end

function nvims
    set items default nvim-lazy nvim-astro
    set config (printf "%s\n" $items | fzf --prompt=" Neovim Config = " --height=~50% --layout=reverse --border --exit-0)
    if [ -z $config ]
        echo "Nothing selected"
        return 0
    else if [ $config = default ]
        set config ""
    end

    env NVIM_APPNAME=$config nvim $argv
end

bind \ca "nvims ."
bind \ce "nvim-lazy ."

abbr -a lvi "nvim-lazy ."
abbr -a nva "nvim-astro ."
