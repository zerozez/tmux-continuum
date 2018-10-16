#!/usr/bin/env bash

OPENRC_NAME="tmux"
SCRIPT_PATH="/etc/init.d/${OPENRC_NAME}"
CONFIG_PATH="/etc/init.d/${OPENRC_NAME}.conf"
RUNLEVEL="default"

source "$CURRENT_DIR/../helpers.sh"
source "$CURRENT_DIR/../variables.sh"

init_script_verify() {
	local options="$@"
    local curr=$(cat ${SCRIPT_PATH} 2>/dev/null)
    local content=""

    read -r -d '' content<<-EOF
    #!/sbin/openrc-run
    #
    # Tmux startup script
    # Generated from tmux-continuum plugin

    command='$(which tmux)'
    command_args="new-session -d ${options}"
    kill_args="kill-server"
    status_args="list-sessions"

    start() {
        ebegin "Starting tmux"
        for tuser in $TMUX_USERS; do
            einfo "Starting tmux for $tuser"
            start-stop-daemon -S -q -x $command -u $tuser \
                    -- $command_args
            retval="$?"
            if [ $retval -ne 0 ]; then
                eerror "Failed with code $retval"
            fi
        done
        eend 0
    }

    stop() {
        local retval=0
        ebegin "Stopping tmux"
        for tuser in $TMUX_USERS; do
            start-stop-daemon -S -q -x $command -u $tuser \
                    -- $kill_args || retval=$?
        done
        eend $retval
    }

    status() {
        for tuser in $TMUX_USERS; do
            out=$(su "$command $status_args" -- $tuser)
            if [ echo $out |grep -q "no server running" ]; then
                einfo "Tmux for user $tuser: running."
            else
                einfo "Tmux for user $tuser: is not running."
            fi
        done
    }
    EOF

    if [ ! $curr == $content ]; then
        echo "$content" | run_cmd_as_su "tee ${SCRIPT_PATH}"
        run_cmd_as_su "chmod +x $SCRIPT_PATH"
        run_cmd_as_su "rc-update add ${OPENRC_NAME} ${RUNLEVEL}"
    fi
}

conf_script_update() {
    local users="$([ ! -z $TMUX_USERS ]&& echo '$TMUX_USERS ')$1"

    read -r -d '' content<<-EOF
    # Configuration file for tmux service
    #
    
    # List of users for whom tmux starts
    TMUX_USERS="'${users}'"

    EOF

    echo "$content" | run_cmd_as_su "tee ${CONFIG_PATH}"
}

openrc_tmux_is_enabled() {
    local user=$1

    rc-status $RUNLEVEL|grep -q "tmux" && ${SCRIPT_PATH} status |grep -q $user
}

enable_tmux_openrc_on_boot() {
    local user=$1
}

main() {
	local options="$(get_tmux_option "$auto_start_config_option" "${auto_start_config_default}")"
    local user=$(whoami)

    if ! openrc_tmux_is_enabled $user; then
        init_script_verify $options
        conf_script_update $user
    fi
}
main
