#!/bin/bash

# sync.sh - config file sync utility
# author: raymond wang
# description: safely links repository config files with local files
# github: github.com/waymondrang/dotfiles

# exit on error
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# config.json file location
CONFIG_FILE="$SCRIPT_DIR/config.json"

print_red() { echo -e "\033[31m${1:-$(cat)}\033[0m"; }
print_green() { echo -e "\033[32m${1:-$(cat)}\033[0m"; }
print_yellow() { echo -e "\033[33m${1:-$(cat)}\033[0m"; }
print_blue() { echo -e "\033[34m${1:-$(cat)}\033[0m"; }
print_magenta() { echo -e "\033[35m${1:-$(cat)}\033[0m"; }
print_cyan() { echo -e "\033[36m${1:-$(cat)}\033[0m"; }
print_white() { echo -e "\033[37m${1:-$(cat)}\033[0m"; }
print_bold() { echo -e "\033[1m${1:-$(cat)}\033[0m"; }
print_dim() { echo -e "\033[2m${1:-$(cat)}\033[0m"; }

print_success() { print_green "[ok] ${1:-$(cat)}"; }
print_error() { print_red "[error] ${1:-$(cat)}"; }
print_warning() { print_yellow "[warn] ${1:-$(cat)}"; }
print_info() { print_white "[info] ${1:-$(cat)}"; }
print_step() { print_cyan "> ${1:-$(cat)}"; }

check_dependencies() {
	if ! command -v jq &>/dev/null; then
		print_error "jq is required but not installed!"
		exit 1
	fi

	if [[ ! -e "$CONFIG_FILE" ]]; then
		print_error "missing config.json expected at ${CONFIG_FILE}!"
		exit 1
	fi
}

# list all program names defined in config.json
get_programs() {
	jq -r 'keys[]' "$CONFIG_FILE"
}

# check whether a program exists in config.json
program_exists() {
	local program="$1"
	jq -e --arg program "$program" '.[$program]' "$CONFIG_FILE" &>/dev/null
}

# print the keys of config.json (program names)
show_programs() {
	print_step "available programs:"
	cat "$CONFIG_FILE" | jq -r "keys[]" | sed "s/^/  /"
}

# safely backs up path by appending .bak
backup_and_remove_path() {
	# target is guaranteed to exist
	local target="$1"
	local backup="${target}.bak"

	# add timestamp if .bak already exists
	if [[ -e "$backup" ]]; then
		backup="${target}.bak.$(date +%s)"
	fi

	# --dereference: always follow symbolic links in SOURCE
	if cp --recursive --dereference "$target" "$backup"; then
		# remove original target
		rm -rf "$target"

		print_info "backed up: existing $(basename "$target") -> $(basename "$backup")"
	else
		print_error "failed to back up $(basename "$target")"
		exit 1
	fi
}

# copies the destination path to source path
copy_dest_to_src() {
	local src="$1"  	# path to repo file/dir
	local dest="$2"		# config locatiosns
	local prog="$3" 	# program name

	if [[ ! -d "$src" ]]; then
		print_info "creating source directory: $(dirname "$src")"
		mkdir -p "$(dirname "$src")"
	fi

	# copy destination files to source
	if cp -r "$dest" "$src"; then
		print_info "copied: $dest -> $src"
	else
		print_error "failed to copy $dest to $src"
		return 1
	fi

	print_info "successfully copied destination to source"
}

# backup and create symlink from src to dest
link_path() {
	local src="$1"  # path to repo file/dir
	local dest="$2" # config location
	local prog="$3"

	# replace $HOME string with actual value
	dest="${dest/\$HOME/$HOME}"

	# resolve src to an absolute path anchored to the script directory
	if [[ "$src" != /* ]]; then
		src="$SCRIPT_DIR/$src"
	fi

	# sanity check dest; could exist but is bad symlink
	if [[ -L "$dest" && ! -e "$dest" ]]; then
		print_warning "bad symbolic link: $dest -> $(readlink $dest)"
		
		# remove bad symlink
		print_info "removing $dest"
		rm -rf "$dest"
	fi

	# -e checks if file exists
	if [[ ! -e "$src" ]]; then
		if [[ -e "$dest" ]]; then
			print_info "destination exists but source does not, copying destination to source"
			copy_dest_to_src "$src" "$dest" "$prog"
			# continue to backup and link destination
		else
			print_error "neither destination nor source exist!"
			return 1
		fi
	fi

	# ensure parent directory exists
	mkdir -p "$(dirname "$dest")"

	# back up anything already at the destination (unless identical symlink)
	# -L checks if file exists and is symbolic link
	if [[ -L "$dest" ]]; then
		local current_target
		current_target="$(readlink "$dest")"

		if [[ "$current_target" == "$src" ]]; then
			print_info "identical symlink: $dest -> $src"
			return 0
		fi

		backup_and_remove_path "$dest"
	elif [[ -e "$dest" ]]; then
		backup_and_remove_path "$dest"
	fi

	ln -s "$src" "$dest"
	print_info "linked: $dest -> $src"
}

# iterate over mappings and create symlinks
sync_program() {
	local prog="$1"

	if ! program_exists "$prog"; then
		print_error "unknown program: $prog"
		print_info "run \"$0 --show-programs\" to see available programs"
		exit 1
	fi

	print_step "syncing $prog"

	local success=0

	local length
	length=$(jq --arg prog "$prog" '.[$prog] | length' "$CONFIG_FILE")

	for ((i = 0; i < length; i++)); do
		# dest_raw and src_raw are processed in link_path
		local dest_raw
		local src_raw

		dest_raw=$(jq -r --arg prog "$prog" --argjson i "$i" '.[$prog][$i] | keys[0]' "$CONFIG_FILE")
		src_raw=$(jq -r --arg prog "$prog" --argjson i "$i" '.[$prog][$i] | .[keys[0]]' "$CONFIG_FILE")

		if ! link_path "$src_raw" "$dest_raw" "$prog"; then
			success=1
		fi
	done

	if [[ "$success" -eq 0 ]]; then
		print_success "$prog synced!"
	else
		print_error "failed to sync $prog"
	fi
}

print_usage() {
	echo ""
	print_bold "usage:"
	echo "  $(basename "$0") <program(s)...>    sync config for programs"
	echo "  $(basename "$0") --all              sync all programs"
	echo "  $(basename "$0") --show-programs    list all programs"
	echo "  $(basename "$0") --help             show this help message"
	echo ""
}

main() {
	check_dependencies

	if [[ $# -eq 0 ]]; then
		print_error "no arguments provided"
		print_usage
		exit 1
	fi

	case "$1" in
	--show-programs)
		show_programs
		;;

        # add alias for --show-programs
        --list-programs)
                show_programs
                ;;

	--help | -h)
		print_usage
		;;

	--all)
		# sync every program in config.json
		programs=$(get_programs)
		for prog in $programs; do
			sync_program "$prog"
		done
		;;

	*)
		# treat all positional arguments as program names
		for prog in "$@"; do
			sync_program "$prog"
		done
		;;
	esac
}

main "$@"
