# Go Lang PATH
if test -d $HOME/.local/go
    set -gx GOPATH $HOME/.local/go
    set -gx PATH $PATH $HOME/.local/go/bin
else
    mkdir -p $HOME/.local/go
end
