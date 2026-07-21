#!/usr/bin/env bash
#
# Checks git-initialization status of base directories and their level-1 subdirectories.
#
# Usage: ./check_git_dirs.sh [root_dir]
#   root_dir defaults to the current directory.
#
# For each base directory (immediate child of root_dir):
#   - always prints "<dir_name> true" or "<dir_name> false"
# For each level-1 subdirectory (immediate child of a base directory):
#   - prints "<dir_name> true" only if it is git-initialized (no output otherwise)

set -euo pipefail

root_dir="${1:-.}"

if [[ ! -d "$root_dir" ]]; then
    echo "Error: '$root_dir' is not a directory" >&2
    exit 1
fi

green='\033[0;32m'
red='\033[0;31m'
yellow='\033[0;33m'
cyan='\033[0;36m'
magenta='\033[0;35m'
blue='\033[1;34m'
reset='\033[0m'

is_git_repo() {
    [[ -d "$1/.git" ]]
}

# Prints "username repo_name" (space-separated) for the origin remote, or nothing if unavailable.
get_remote_info() {
    local dir="$1" url
    url="$(git -C "$dir" remote get-url origin 2>/dev/null)" || return 1
    url="${url%.git}"

    if [[ "$url" =~ ^git@[^:]+:(.+)/([^/]+)$ ]]; then
        echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
    elif [[ "$url" =~ ^[a-zA-Z]+://[^/]+/(.+)/([^/]+)$ ]]; then
        echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
    else
        return 1
    fi
}

print_result() {
    local dir="$1" prefix="$2"

    if is_git_repo "$dir"; then
        local remote_info username repo
        if remote_info="$(get_remote_info "$dir")"; then
            username="${remote_info% *}"
            repo="${remote_info#* }"
            echo -e "${prefix}${green}true${reset} ${yellow}${username}${reset}/${cyan}${repo}${reset}"
        else
            echo -e "${prefix}${green}true${reset}"
        fi
    elif [[ "${3:-}" == "required" ]]; then
        echo -e "${prefix}${red}false${reset}"
    fi
    return 0
}

for base_dir in "$root_dir"/*/; do
    [[ -d "$base_dir" ]] || continue
    base_name="$(basename "$base_dir")"

    print_result "$base_dir" "${magenta}${base_name}${reset} " "required"

    # Collect level-1 subdirs that are git-initialized so tree connectors
    # (├── / └──) can be picked based on which entry is actually last.
    true_subdirs=()
    for sub_dir in "$base_dir"*/; do
        [[ -d "$sub_dir" ]] || continue
        is_git_repo "$sub_dir" && true_subdirs+=("$sub_dir")
    done

    last_index=$(( ${#true_subdirs[@]} - 1 ))
    for i in "${!true_subdirs[@]}"; do
        sub_dir="${true_subdirs[$i]}"
        sub_name="$(basename "$sub_dir")"
        if [[ "$i" -eq "$last_index" ]]; then
            connector="└── "
        else
            connector="├── "
        fi
        print_result "$sub_dir" "${connector}${blue}${sub_name}${reset} "
    done
done
