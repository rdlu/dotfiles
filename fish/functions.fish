function fancy_print_line
    set DEF_COLOR red
    if set -q argv[1]
        set_color $DEF_COLOR
        printf $argv"\n"
    else
        fancy_print_line "It's just a function to echo in fancy way."
    end
end

function fancy_print_title
    set DEF_COLOR purple
    if set -q argv[1]
        set_color $DEF_COLOR
        echo --------------------------------------
        fancy_print_line $argv
        set_color $DEF_COLOR
        echo --------------------------------------
    else
        fancy_print_title "It's just a function to echo in fancy way."
    end
end

function ldenv --description "<file_path> Set env variables from a .env file"
    if set -q argv[1]
        set FILE argv[1]
    else
        set FILE .env
    end

    for i in (cat $FILE)
        if test (echo $i | sed -E 's/^[[:space:]]*(.).+$/\\1/g') != "#"
            echo $i
            set arr (echo $i |tr = \n)
            set -gx $arr[1] $arr[2]
        end
    end
end

function isWSL2
    set isWSL2 (uname -a | grep WSL2)
    not test -z $isWSL2
end
