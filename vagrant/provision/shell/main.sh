#!/bin/bash

CONFIG_DIR='/vagrant/vagrant'
FILES="$CONFIG_DIR/files"
FILES_LOCAL="$CONFIG_DIR/local/files"
PROJECT_ROOT=$__PROJECT_ROOT
SERVICES=''
PACKAGES="vim multitail screen htop lynx git git-flow "

main() {
    local install_rvm_ruby_version='ruby-2.2.3'

    local project_root="$(sed -e 's/[\/&]/\\&/g' <<< $PROJECT_ROOT)"

    # Files in $FILES_LOCAL that must exist before provisioning
    important_local_files=""

    # Check local files
    for f in $important_local_files; do
        if [[ ! -e "$FILES_LOCAL/$f" ]]; then
            error -q ' '
            error "File missing: config/local/files/$f"
            error -q ' '
            stop 1
        fi
    done

    stop_services

    task 'Generating locale'
    provision "locale-gen de_DE.UTF-8"

    if [[ "$__ONLINE" == 'true' ]]; then
        apt_upgrade
        install_packages
    fi

    task 'Configuring .bashrc'
    provision "sed 's/<%= PROJECT_ROOT %>/$project_root/g' '$FILES/bashrc/vagrant.bashrc.tpl' > /home/vagrant/.bashrc"
    provision "cp '$FILES/bashrc/root.bashrc' /root/.bashrc"

    start_services
}

apt_upgrade() {
    local file_apt_last_upgrade apt_last_upgrade today
    file_apt_last_upgrade="$HOME/.last-apt-upgrade"

    [ -f "$file_apt_last_upgrade" ] \
        && apt_last_upgrade="$(cat "$file_apt_last_upgrade")" \
        || apt_last_upgrade="0"
    apt_last_upgrade="${apt_last_upgrade:-0}"

    today="$(date +"%Y%m%d")"
    touch "$file_apt_last_upgrade"

    if [ "$today" -gt "$apt_last_upgrade" ]; then
        task "Upgrading packages"

        subtask "Updating apt-cache"
        provision "apt-get update"

        subtask "Upgrading packages (might take a view minutes)"
        DEBIAN_FRONTEND=noninteractive \
            provision "apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' -q upgrade"

        echo "$today" > "$file_apt_last_upgrade"
    fi
}

install_packages() {
    local installed_packages install_packages
    task 'Installing packages'

    subtask 'Fetching list of installed packages'
    installed_packages="$(dpkg -l | awk '{print $2}')"

    for p in $PACKAGES; do
        echo "$installed_packages" | grep "^$p$" >/dev/null
        if [ $? -ne 0 ]; then
            install_packages+="$p "
        fi
    done

    if [ -n "$install_packages" ]; then
        subtask "To be installed: $install_packages"
            subtask "Installing:"

        for p in $install_packages; do

            subtask2 "$p"
            DEBIAN_FRONTEND=noninteractive \
                provision "apt-get install -y '$p'"
        done
    else
        subtask2 '... nothing to do'
    fi
}

stop_services() {
    echo '# Stopping services'
    for s in $SERVICES; do
        service $s status >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            subtask "$s"
            provision "service '$s' stop"
        fi
    done
}

start_services() {
    echo '# Starting services'
    for s in $SERVICES; do
        subtask "$s"
        # chkconfig $s on || exit $?
        provision "service '$s' start"
    done
}
