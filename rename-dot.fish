#!/usr/bin/env fish

# List of directories to process
set directories idea git scripts hypr terminal lazyvim vim systemd

# Process each directory
for dir in $directories
    # Check if directory exists
    if test -d $dir
        echo "Processing directory: $dir"

        # Find all dot directories in the current directory and its subdirectories
        # Using find to locate directories that start with a dot
        for dotdir in (find $dir -type d -name ".*" ! -name "." ! -name "..")
            # Get the base name of the directory
            set basename (basename $dotdir)
            # Get the parent directory
            set parent (dirname $dotdir)
            # Create new name by replacing the leading dot with 'dot-'
            set newname (string replace -r '^\.' 'dot-' $basename)
            # Full path for the new directory
            set newpath "$parent/$newname"

            # Rename the directory
            if test -e $newpath
                echo "Warning: $newpath already exists, skipping..."
            else
                mv $dotdir $newpath
                echo "Renamed: $dotdir → $newpath"
            end
        end
    else
        echo "Directory not found: $dir"
    end
end
