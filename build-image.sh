#!/usr/bin/env bash

set -e
set -u

show_help() {
	cat <<EOF
usage: ${0##*/} <build_directory> <output_file>

Builds an IHUOS chroot inside <build_directory> and compresses it to <output_file>
EOF
}

if [[ "$1" == "--help" ]]; then
	show_help
	exit
fi

if [[ "$EUID" -ne 0 ]]; then
	echo "This script must be run as root"
	exit 1
fi

build_dir="$1"
output_file="$2"

# Make sure the build directory exists
mkdir -p "$build_dir"

# Mount the directory to itself to make sure it is a mountpoint
mount --bind "$build_dir" "$build_dir"

# Install the system
pacstrap "$build_dir" base

# Perform exrta operations inside the system
arch-chroot "$build_dir" <<EOF
# Create a regular user
useradd --create-home --user-group user
EOF

# Compress the image
echo "Compressing the chroot, this may take a moment..."
bsdtar -cf - -C "$build_dir/" . | gzip -c -1 - > "$output_file"

# Unmount the directory from itself
umount "$build_dir"
