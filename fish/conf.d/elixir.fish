# Elixir / Erl
# tell exqlite that we wish to use some other sqlite installation. this will prevent sqlite3.c and friends from compiling
set -gx EXQLITE_USE_SYSTEM 1

# Tell exqlite where to find the `sqlite3.h` file
set -gx EXQLITE_SYSTEM_CFLAGS -I/usr/include

# tell exqlite which sqlite implementation to use
set -gx EXQLITE_SYSTEM_LDFLAGS '-L/usr/lib64 -lsqlite3'

# Erlang compile flags for fedora & wx-config
set -gx ERL_AFLAGS '-kernel shell_history enabled'
set -gx KERL_CONFIGURE_OPTIONS "--enable-wx --with-wx --enable-webview --with-wx-config=/usr/bin/wx-config-3.2"
set -gx KERL_BUILD_DOCS yes
