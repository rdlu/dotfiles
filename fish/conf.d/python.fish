# Python PIP and VENV
#if type -q python
#    set -gx PYTHONPATH (python -c "import site, os; print(os.path.join(site.USER_BASE, 'lib', 'python', 'site-packages'))"):$PYTHONPATH
#end
#set -gx VIRTUAL_ENV_DISABLE_PROMPT 0
# disabling for rtx/asdf
#set -gx PIP_REQUIRE_VIRTUALENV 0

# thanks https://alexwlchan.net/2023/fish-venv/
function venv --description "Create and activate a new virtual environment"
    if test -e .venv
        set_color purple
        echo "Activating python venv using fish"
        source .venv/bin/activate.fish
    else
        echo "Creating virtual environment in "(pwd)"/.venv"
        python3 -m venv .venv --upgrade-deps
        source .venv/bin/activate.fish

        # Append .venv to the Git exclude file, but only if it's not
        # already there.    
        if test -e .git
            set line_to_append ".venv"
            set target_file ".git/info/exclude"

            if not grep --quiet --fixed-strings --line-regexp "$line_to_append" "$target_file" 2>/dev/null
                echo "$line_to_append" >>"$target_file"
            end
        end
    end
end
