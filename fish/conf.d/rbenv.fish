which rbenv > /dev/null
if test $status -eq 0
    status --is-interactive; and source (rbenv init -|psub)
end