#!/bin/sh

release=""
installer=""
systemd_path=""
function check_os_type() {
    if [[ -f /etc/redhat-release ]]; then
        release="centos"
        installer="yum -y"
        system_path="/usr/lib/systemd/system"
    elif cat /etc/issue | grep -Eqi "debian"; then
        release="debian"
        installer="apt -y"
        system_path="/lib/systemd/system"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        release="ubuntu"
        installer="apt-get -y"
        system_path="/lib/systemd/system"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
        installer="yum -y"
        system_path="/usr/lib/systemd/system"
    elif cat /proc/version | grep -Eqi "debian"; then
        release="debian"
        installer="apt -y"
        system_path="/lib/systemd/system"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        release="ubuntu"
        installer="apt-get -y"
        system_path="/lib/systemd/system"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
        installer="yum"
        system_path="/usr/lib/systemd/system"
    else
        echo 'OS is not be supported...'
        exit 1
    fi
}

#reset vimrc.
function reset_vimrc() {
    if [[ -e /etc/virc ]]; then
        sed -i "s/set compatible/set nocompatible/g" /etc/virc
        if ! grep -q "set backspace" /etc/virc; then
            sed -i '$a\set backspace=2' /etc/virc
        fi

        if ! grep -q "set ts" /etc/virc; then
            sed -i '$a\set ts=4' /etc/virc
        fi

        if ! grep -q "set softtabstop" /etc/virc; then
            sed -i '$a\set softtabstop=4' /etc/virc
        fi

        if ! grep -q "set shiftwidth" /etc/virc; then
            sed -i '$a\set shiftwidth=4' /etc/virc
        fi

        if ! grep -q "set expandtab" /etc/virc; then
            sed -i '$a\set expandtab' /etc/virc
        fi

        if ! grep -q "set autoindent" /etc/virc; then
            sed -i '$a\set autoindent' /etc/virc
        fi
    fi
    
    if [[ -e /etc/vim/vimrc.tiny ]]; then
        sed -i "s/set compatible/set nocompatible/g" /etc/vim/vimrc.tiny
        if ! grep -q "set backspace" /etc/vim/vimrc.tiny; then
            sed -i '$a\set backspace=2' /etc/vim/vimrc.tiny
        fi

        if ! grep -q "set ts" /etc/vim/vimrc.tiny; then
            sed -i '$a\set ts=4' /etc/vim/vimrc.tiny
        fi

        if ! grep -q "set softtabstop" /etc/vim/vimrc.tiny; then
            sed -i '$a\set softtabstop=4' /etc/vim/vimrc.tiny
        fi

        if ! grep -q "set shiftwidth" /etc/vim/vimrc.tiny; then
            sed -i '$a\set shiftwidth=4' /etc/vim/vimrc.tiny
        fi

        if ! grep -q "set expandtab" /etc/vim/vimrc.tiny; then
            sed -i '$a\set expandtab' /etc/vim/vimrc.tiny
        fi

        if ! grep -q "set autoindent" /etc/vim/vimrc.tiny; then
            sed -i '$a\set autoindent' /etc/vim/vimrc.tiny
        fi
    fi 
}

#reset bashrc.
function reset_bashrc() {
    if [[ x"${release}" == x"centos" ]]; then
cat <<'EOF' > ~/.bashrc

# User specific aliases and functions

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi
EOF
    elif [[ x"${release}" == x"debian" ]]; then
        cat <<'EOF' > ~/.bashrc
# ~/.bashrc: executed by bash(1) for non-login shells.

# Note: PS1 and umask are already set in /etc/profile. You should not
# need this unless you want different defaults for root.
# PS1='${debian_chroot:+($debian_chroot)}\h:\w\$ '
# umask 022

# You may uncomment the following lines if you want `ls' to be colorized:
export LS_OPTIONS='--color=auto'
eval "`dircolors`"
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -l'
alias l='ls $LS_OPTIONS -lA'
#
# Some more alias to avoid making mistakes:
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
EOF
    else
        echo 'OS is not be supported...'
    fi

    source ~/.bashrc
}

check_os_type
reset_vimrc
reset_bashrc
echo "set mouse=" > ~/.vimrc
