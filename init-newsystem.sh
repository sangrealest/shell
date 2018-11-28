#!/bin/bash

echo "set up for bash"

echo >>$HOME/.bashrc <<EOF
shopt -s histappend
PROMPT_COMMAND='history -a'

alias grep='grep --color=auto -i'
alias vi='vim'
alias ll='ls  --color=auto -hltr'
alias la='ls --color=auto -alhtr'
export PS1="\[\e[00;32m\][\[\e[0m\]\[\e[00;31m\]\u\[\e[0m\]\[\e[00;32m\]@\[\e[0m\]\[\e[00;33m\]\H:\[\e[0m\]\[\e[00;35m\]\w\[\e[0m\]\[\e[00;32m\]\A]\[\e[0m\]\[\e[00;36m\]\\$\[\e[0m\]"
EOF

echo "setting up vim"

echo >$HOME/.vimrc <<EOF
set number
set ruler
set laststatus=2
set showcmd
set magic
set history=100
set showmatch
set ignorecase
set cursorline
let loaded_matchparen=1
set lazyredraw
set tabstop=4
set softtabstop=4
set expandtab
set hlsearch
set incsearch
EOF

echo "setting up ssh_config"
echo StrictHostKeyChecking no >> /etc/ssh/ssh_config
