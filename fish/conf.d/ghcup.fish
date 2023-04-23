
if test -e $HOME/.ghcup/
  set -q GHCUP_INSTALL_BASE_PREFIX[1]; or set GHCUP_INSTALL_BASE_PREFIX $HOME ; set -gx PATH $HOME/.cabal/bin $PATH /home/rdlu/.ghcup/bin # ghcup-env
end
