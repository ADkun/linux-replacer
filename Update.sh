#! /bin/bash

echo "Usage: sh Update.sh"

# contains ClientService/ and etc/
INSTALLPATH=/tmp/test
DEFAULTOWNER=root
DEFAULTGROUP=root
DEFAULTRIGHT=400

tstr=$(date '+%Y%m%d%H%M%S')

function set_printer() {
    set_red="echo -en \e[91m"
    set_green="echo -en \e[32m"
    set_yellow="echo -en \e[33m"
    set_blue="echo -en \e[36m"
    unset_color="echo -en \e[0m"
    print_red() {
        $set_red
        echo -e "${1}"
        $unset_color
    }
    print_yellow() {
        $set_yellow
        echo -e "${1}"
        $unset_color
    }
    print_green() {
        $set_green
        echo -e "${1}"
        $unset_color
    }
    print_blue() {
        $set_blue
        echo -e "${1}"
        $unset_color
    }
}
set_printer

function do_confirm() {
    while true; do
        read -r -p '(y/n)' confirm
        case "${confirm}" in
        [Yy])
            return 0
            ;;
        [Nn])
            return 1
            ;;
        *) ;;

        esac
    done
}

function log_normal() {
    msg=$1
    print_blue "${msg}"
}

function log_info() {
    msg=$1
    print_green "[ INFO ] ${msg}"
}

function log_warn() {
    msg=$1
    print_yellow "[ WARN ] ${msg}"
}

function log_err() {
    msg=$1
    p=$(print_red "[ ERROR ] ${msg}")
    echo "${p}" >&2
}

function log_debug() {
    if [[ ! ${debug_flag} ]]; then
        return 1
    fi
    msg=$1
    print_yellow "[ DEBUG ] ${msg}"
}

function log_err_exit() {
    msg=$1
    log_err "${msg}"
    exit 1
}

function get_path() {
    # exec_path=$(pwd) # 执行目录
    script_path=$(
        cd "$(dirname "${0}")" || log_err_exit "Get script_path failed."
        pwd
    )
}
get_path

function init_paths() {
    if [[ ! -d ${INSTALLPATH} ]]; then
        log_err_exit "${INSTALLPATH} doesn't exists."
    fi

    files_path=${script_path}/files
    if [[ ! -d ${files_path} ]]; then
        log_err_exit "${files_path} doesn't exists."
    fi

    cd "${files_path}" || log_err_exit "cd ${files_path} failed."
    rel_paths=$(find . -type f)
    log_debug "init_paths() rel_paths: ${rel_paths}"
}

function chown_files() {
    cd "${files_path}" || log_err_exit "cd ${files_path} failed."
    if chown -R ${DEFAULTOWNER}:${DEFAULTGROUP} "${files_path}" && chmod -R ${DEFAULTRIGHT} "${files_path}"; then
        log_info "Change owner ${DEFAULTOWNER}:${DEFAULTGROUP} of ${files_path}"
        log_info "Change mod ${DEFAULTRIGHT} of ${files_path}"
    else
        log_err "Change owner and mod of ${files_path} failed."
    fi
}

function backup_files() {
    local bak_path=${script_path}/bak
    if [[ ! -d ${bak_path} ]]; then
        mkdir "${bak_path}"
    fi

    echo "${rel_paths}" | while read -r line; do
        local src_path="${INSTALLPATH}/${line}"
        local target_path="${bak_path}/${line}.${tstr}"
        local temp_dir=${target_path%/*}
        mkdir -p "${temp_dir}"
        if cp -p "${src_path}" "${target_path}"; then
            log_info "Backup to ${target_path}"
        else
            log_err "Backup ${src_path} failed."
        fi
    done
}

function replace_files() {
    echo "${rel_paths}" | while read -r line; do
        local src_path="${files_path}/${line}"
        local target_path="${INSTALLPATH}/${line}"
        local target_dir=${target_path%/*}
        if [[ ! -d "${target_dir}" ]]; then
            if mkdir -p "${target_dir}"; then
                log_info "Mkdir ${target_dir} success"
            else
                log_err "Mkdir ${target_dir} failed"
            fi
        fi
        if which yes >/dev/null; then
            if yes | cp -p -f "${src_path}" "${target_path}"; then
                log_info "Patch ${target_path}"
            else
                log_err "Patch ${target_path} failed."
            fi
        else
            if cp -p -f "${src_path}" "${target_path}"; then
                log_info "Patch ${target_path}"
            else
                log_err "Patch ${target_path} failed."
            fi
        fi
    done
}

function main() {
    first_param=$1
    if [ "${first_param}" = "debug" ]; then
        debug_flag=true
    fi

    init_paths
    chown_files
    backup_files
    replace_files

    log_info "Patch done. Check if some files doesn't patch succeed."
}
main "$1"
