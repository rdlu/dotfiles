set ADB_TOOLS_DIR $HOME/Programs/Android/sdk/platform-tools
if test -e $ADB_TOOLS_DIR
    set -gx PATH $PATH $ADB_TOOLS_DIR
end
