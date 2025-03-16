# Shell options
set -o vi
stty -ixon              # Re-enable Ctrl+S for forward search
shopt -s histappend     # Don't overwrite history of other terminals
HISTCONTROL=ignoredups  # Don't add duplicate commands to history
HISTSIZE=100000
HISTFILESIZE=100000

# PATH
export PATH="/Users/ben/.bun/bin:$PATH"
export PATH="/Users/ben/.local/bin:$PATH"

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

# tmux_alarm: Broadcast alarm to tmux
tmux_alarm() {
	# If not in tmux, do nothing
	[ -n $TMUX ] || return

	mapfile -t sessions < <(tmux list-sessions -F '#{session_name}')

	broadcast_status_right() {
		for session in "${sessions[@]}"; do
			tmux set-option -t "$session" status-right "$1"
		done
	}

	clear_alarm() {
		kill $flash_alarm_pid
		broadcast_status_right ""
	}

	flash_alarm() {
		local alarm_window="$(tmux display-message -p '#S:#I')"
		while true; do
			broadcast_status_right "$alarm_window ⏰"
			sleep 1
			broadcast_status_right "$alarm_window   "
			sleep 1
		done
	}

	flash_alarm &
	flash_alarm_pid=$!

	# Clear alarm even if they exit with Ctrl + C
	trap 'clear_alarm; echo; return 0' SIGINT

	read -r -p "[⏰] $(basename $0) called alarm" response
	clear_alarm

	return 0
}
export -f tmux_alarm

# tmux_error: Broadcast error to tmux
tmux_error() {
	# If not in tmux, do nothing
	[ -n $TMUX ] || return

	status=$1

	# If called without status code, set EXIT trap and return
	if [ -z $status ]; then
		trap 'status=$?; tmux_error $status; exit $status' EXIT
		return
	fi

	# If status code isn't an error, do nothing
	[ $status -eq 0 ] && return

	# If status code is an error, broadcast it
	mapfile -t sessions < <(tmux list-sessions -F '#{session_name}')

	broadcast_status_right() {
		for session in "${sessions[@]}"; do
			tmux set-option -t "$session" status-right "$1"
		done
	}

	clear_error() {
		kill $flash_error_pid
		broadcast_status_right ""
	}

	flash_error() {
		local error_window="$(tmux display-message -p '#S:#I')"
		while true; do
			broadcast_status_right "$error_window 🚨"
			sleep 1
			broadcast_status_right "$error_window   "
			sleep 1
		done
	}

	flash_error &
	flash_error_pid=$!

	# Clear error even if they exit with Ctrl + C
	trap 'clear_error; echo; exit 0' SIGINT

	read -r -p "[🚨] $(basename $0) failed with error $status" response
	clear_error
}
export -f tmux_error
