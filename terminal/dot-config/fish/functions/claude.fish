function claude --wraps claude --description 'Run Claude Code at low CPU and IO weight'
    systemd-run --user --scope --quiet -p CPUWeight=30 -p IOWeight=30 -- (command -s claude) $argv
end
