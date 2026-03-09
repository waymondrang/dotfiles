#!/bin/bash

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
backup_path() {
	local target="$1"
	local backup="${target}.bak"

	# add timestamp if .bak already exists
	if [[ -e "$backup" ]]; then
		backup="${target}.bak.$(date +%s)"
	fi

	mv "$target" "$backup"
	print_warning "backed up existing $(basename "$target") to $(basename "$backup")"
}

# backup and create symlink from src to dest
link_path() {
	local src="$1"  # path to repo file/dir
	local dest="$2" # config location

	# replace $HOME string with actual value
	dest="${dest/\$HOME/$HOME}"

	# resolve src to an absolute path anchored to the script directory
	if [[ "$src" != /* ]]; then
		src="$SCRIPT_DIR/$src"
	fi

	# -e checks if file exists
	if [[ ! -e "$src" ]]; then
		print_warning "source does not exist, skipping: $src"
		return
	fi

	# ensure parent directory exists
	mkdir -p "$(dirname "$dest")"

	# back up anything already at the destination (unless identical symlink)
	if [[ -L "$dest" ]]; then
		local current_target
		current_target="$(readlink "$dest")"

		if [[ "$current_target" == "$src" ]]; then
			print_info "identical symlink: $dest"
			return
		fi

		backup_path "$dest"
	elif [[ -e "$dest" ]]; then
		backup_path "$dest"
	fi

	ln -s "$src" "$dest"
	print_success "linked: $dest -> $src"
}

# iterate over mappings and create symlinks
sync_program() {
	local program="$1"

	if ! program_exists "$program"; then
		print_error "unknown program: $program"
		print_info "run \"$0 --show-programs\" to see available programs"
		exit 1
	fi

	print_step "syncing $program"

	local length
	length=$(jq --arg program "$program" '.[$program] | length' "$CONFIG_FILE")

	for ((i = 0; i < length; i++)); do
		local dest
		local src

		dest=$(jq -r --arg program "$program" --argjson i "$i" '.[$program][$i] | keys[0]' "$CONFIG_FILE")
		src=$(jq -r --arg program "$program" --argjson i "$i" '.[$program][$i] | .[keys[0]]' "$CONFIG_FILE")

		link_path "$src" "$dest"
	done

	print_success "$program synced!"
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

	--help | -h)
		print_usage
		;;

	--all)
		# sync every program in config.json
		programs=$(get_programs)
		for program in $programs; do
			sync_program "$program"
		done
		;;

	*)
		# treat all positional arguments as program names
		for program in "$@"; do
			sync_program "$program"
		done
		;;
	esac
}

main "$@"
