# Scrub PYTHONHOME/PYTHONPATH leaked by the Tidewave AppImage (breaks system python).
#
# Tidewave ships as an AppImage that self-mounts under /tmp/.mount_tidewaXXXXXX/ and
# exports PYTHONHOME/PYTHONPATH pointing at its bundled runtime into every child process.
# That mountpoint is the wrong CPython version and is often already unmounted, so the
# system interpreter dies with "ModuleNotFoundError: No module named 'encodings'".
#
# Conditional on the /tmp/.mount_* signature: a no-op on machines without Tidewave and
# leaves any legitimate PYTHONHOME untouched. Lives in the native conf.d so fish sources
# it for ALL sessions (interactive and `fish -c`), unlike ~/.dotfiles/fish/conf.d.
if string match -q '/tmp/.mount_*' -- "$PYTHONHOME"
    set -e PYTHONHOME
    set -e PYTHONPATH
end
