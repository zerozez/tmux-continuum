#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/helpers.sh"
source "$CURRENT_DIR/variables.sh"

is_tmux_automatic_start_enabled() {
	local auto_start_value="$(get_tmux_option "$auto_start_option" "$auto_start_default")"
	[ "$auto_start_value" == "on" ]
}

get_service_type() {
    if [ $(uname) == "Darwin" ]; then
        return "osx"
    elif [ $(ps -o comm= -p1) == 'systemd' ]; then
        return "systemd"
    elif [ ! -z $(which openrc-init) ]; then
        return "openrc"
    fi
}

main() {
    local service=$(get_service_type)
	if is_tmux_automatic_start_enabled; then
			"$CURRENT_DIR/handle_tmux_automatic_start/${service}_enable.sh"
	else
			"$CURRENT_DIR/handle_tmux_automatic_start/${service}_disable.sh"
	fi
}
main
