function jq-format --description "Outputs Pretty JSON inplace using JQ"
    jq '.' $argv[1] >temp.formatted.json
    mv temp.formatted.json $argv[1]
end

function jq-format-2 --description "Outputs Pretty JSON in a new formatted file using JQ"
    set filename (basename $argv[1] | cut -d . -f1)
    set extension (basename $argv[1] | cut -d . -f2)
    jq '.' $argv[1] >$filename.formatted.$extension
end
