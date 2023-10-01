# tell exqlite that we wish to use some other sqlite installation. this will prevent sqlite3.c and friends from compiling
set -gx EXQLITE_USE_SYSTEM 1

# Tell exqlite where to find the `sqlite3.h` file
set -gx EXQLITE_SYSTEM_CFLAGS -I/usr/include

# tell exqlite which sqlite implementation to use
set -gx EXQLITE_SYSTEM_LDFLAGS '-L/lib -lsqlite3'
