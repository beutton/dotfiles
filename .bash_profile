# Shell options
set -o vi
shopt -s histappend     # Don't overwrite history of other terminals
stty -ixon              # Re-enable Ctrl+S for forward search
HISTCONTROL=ignoredups  # Don't write duplicate commands
HISTSIZE=100000
HISTFILESIZE=100000

# PATH
export PATH="/Users/ben/.bun/bin:$PATH"

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
export HOMEBREW_NO_ENV_HINTS=1
[ -r /opt/homebrew/etc/profile.d/bash_completion.sh ] && \
	. /opt/homebrew/etc/profile.d/bash_completion.sh

# Prompt
PROMPT_COMMAND=prompt
prompt() {
	# Sync history across terminals
	history -a && history -n
	export PS1="[\u@\h \W]\$ "
	# Add git branch to prompt
	BRANCH="$(git branch --show-current 2>/dev/null)"
	[ -n "$BRANCH" ] && export PS1="[\u@\h \W]($BRANCH)\$ "
}

# Commands
alias c=clone
clone() {
	error() {
		echo "$@" >/dev/stderr
		exit 1
	}

	# If no argument, open lfcd in Repos/github.com
	if [ -z $1 ]; then
		lfcd ~/Repos/github.com
		return
	fi

	# Remove query parameters from URL
	url=$(echo $1 | sed 's/\?.*$//')

	case $url in
		https://github.com/*)
			path=${url#https://github.com/}
			domain="github.com"
			;;
		git@github.com:*)
			path=${url#git@github.com:}
			domain="github.com"
			;;
		https://huggingface.co/spaces/*)
			path=${url#https://huggingface.co/spaces/}
			domain="huggingface.co"
			url="https://huggingface.co/spaces/$path.git"
			;;
		https://huggingface.co/*)
			path=${url#https://huggingface.co/}
			domain="huggingface.co"
			url="https://huggingface.co/$path.git"
			;;
		*)
			echo "Unsupported URL format"
			exit 1
			;;
	esac

	# Common extraction and target directory construction
	user=$(echo "$path" | cut -d'/' -f1)
	repo=$(echo "$path" | cut -d'/' -f2 | sed 's/\.git$//')
	target_dir="$HOME/Repos/$domain/$user/$repo"

	if [ -z $user ] || [ -z $repo ]; then
		error "Error: Could not parse username or repository name from URL"
	fi

	mkdir -p $target_dir 2>/dev/null

	echo "Cloning $url to $target_dir..."
	git clone $url $target_dir

	if [ $? -ne 0 ]; then
		error "Failed to clone the repository"
	fi

	cd $target_dir
	echo "Now in $PWD"
}

# lfcd: Use lf file manager to cd
lfcd() {
	command -v lf >/dev/null 2>&1 || return 127
	tmp="$(mktemp)"
	lf -last-dir-path="$tmp" "$@"
	[ ! -f "$tmp" ] && return
	dir="$(cat "$tmp")"
	rm -f "$tmp"
	[ ! -d "$dir" ] || [ "$dir" = "$(pwd)" ] && return
	cd "$dir"
}
