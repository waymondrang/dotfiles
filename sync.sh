#!/bin/bash

# exit on error
set -e

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
print_info() { print_blue "[info] ${1:-$(cat)}"; }
print_step() { print_cyan "> ${1:-$(cat)}"; }

declare -A FILE_MAPPINGS=(
	# dunst
	["$HOME/.config/dunst"]="./dunst"

	# fontconfig
	["$HOME/.config/fontconfig"]="./fontconfig"

	# foot
	["$HOME/.config/foot"]="./foot"

	# hypr
	["$HOME/.config/hypr/hypridle.conf"]="./hypr"
	["$HOME/.config/hypr/hyprland.conf"]="./hypr"
	["$HOME/.config/hypr/hyprlock.conf"]="./hypr"

	# nvim
	["$HOME/.config/hypr/hypridle.conf"]="./hypr"
	["$HOME/.config/hypr/hyprland.conf"]="./hypr"
	["$HOME/.config/hypr/hyprlock.conf"]="./hypr"

	# nvim
	["$HOME/.config/nvim/init.lua"]="./nvim"
	["$HOME/.config/nvim/lua/config"]="./nvim/config"
	["$HOME/.config/nvim/lua/plugins"]="./nvim/plugins"

	# tmux
	["$HOME/.tmux.conf"]="./tmux/"

	# tofi
	["$HOME/.config/tofi"]="./tofi"

	# waybar
	["$HOME/.config/waybar"]="./waybar"

)

# create directory if doesn't exist
create_directories() {
	for dest in "${FILE_MAPPINGS[@]}"; do
		mkdir -p "$dest"
		exit_code=$?

		if [[ $exit_code -ne 0 ]]; then
			print_error "could not create directory: $dest"
		fi
	done
}

# copy files and directories
sync_files() {
	for src in "${!FILE_MAPPINGS[@]}"; do
		dest="${FILE_MAPPINGS[$src]}"

		if [[ -e "$src" ]]; then
			if [[ -d "$src" ]]; then
				print_info "copying directory: $src -> $dest"

				cp -r "$src"/* "$dest" 2>/dev/null
				exit_code=$?

				if [[ $exit_code -ne 0 ]]; then
					print_error "could not copy from $src"
				fi
			else
				print_info "copying file: $src -> $dest"

				cp "$src" "$dest" 2>/dev/null
				exit_code=$?

				if [[ $exit_code -ne 0 ]]; then
					print_error "could not copy $src"
				fi
			fi
		else
			print_warning "$src does not exist, skipping..."
		fi
	done
}

print_step "syncing dotfiles..."

create_directories
sync_files

print_success "sync completed"
