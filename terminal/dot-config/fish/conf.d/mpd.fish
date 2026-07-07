# Point MPD clients (mpc, rmpc, ncmpcpp, ...) at the socket-activated MPD.
# The user mpd.socket unit listens on $XDG_RUNTIME_DIR/mpd/socket; when systemd
# hands MPD its sockets, the bind_to_address in mpd.conf is ignored, so clients
# relying on the old $XDG_RUNTIME_DIR/mpd-socket path fail to connect.
if test -n "$XDG_RUNTIME_DIR"
    set -gx MPD_HOST $XDG_RUNTIME_DIR/mpd/socket
end
