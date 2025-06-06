function bw-u --description "unlocks bw and sets the session"
    set -gx BW_SESSION (bw unlock --raw)
end
