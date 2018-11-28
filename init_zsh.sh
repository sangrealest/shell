#!/bin/bash
#Author:Shanker
#set -x
#set -u

clear
echo ""
echo "#############################################################"
echo "# Automatically to  Install oh-my-zsh and initialize it     #"
echo "# Intro: https://github.com/sangrealest/shanker             #"
echo "# Author: Shanker<shanker@yeah.net>                         #"
echo "#############################################################"
echo ""


#if [ `id -u` -ne 0 ]
#then
#    echo "Need root to run is, try with sudo"
#    exit 1
#fi

function checkOs(){
    if [ -f /etc/redhat-release ]
    then
        OS="CentOS"
    elif [ ! -z "`cat /etc/issue | grep -i bian`" ]
    then
        OS="Debian"
    elif [ ! -z "`cat /etc/issue | grep -i ubuntu`" ]
    then
        OS="Ubuntu"
    else
        echo "Not supported OS"
        exit 1
    fi
} 

function installSoftware(){

if [ "$OS" == 'CentOS' ]
then
	sudo yum -y -q install zsh git vim
else
	sudo apt-get -y install zsh git vim
fi

zshPath="`which zsh`"
user=$(whoami)
}

function downloadFile(){
    cd ~
    if [ ! -d ~/.oh-my-zsh ]
    then
        git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
    fi

    if [ ! -d ~/autojump ]
    then
        git clone https://github.com/joelthelion/autojump.git
    fi

    if [ ! -d ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]
    then
        git clone https://github.com/sangrealest/zsh-autosuggestions.git ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
    fi

    if [ ! -d ~/initzsh ]
    then
        git clone https://github.com/sangrealest/initzsh 
    fi
}

function installAutojump(){
    autojump_path=$(which autojump)
    if [ $? -ne 0 ]
    then
        cd ~/autojump
        python install.py
    fi

#cat >>~/.zshrc<<EOF
#[[ -s ~/.autojump/etc/profile.d/autojump.sh ]] && source ~/.autojump/etc/profile.d/autojump.sh
#autoload -U compinit && compinit -u
#EOF

}

function configZsh(){
    if [ -f "~/.zsh_history" ]
    then
        mv ~/.zsh_history{.,backup}
    fi
    sudo usermod -s "$zshPath" $user
    cp ~/initzsh/zshrc ~/.zshrc
    chmod -R 755 ~/.oh-my-zsh/custom/plugins
   
}

function configGitconfig(){
    if [ -f "~/.gitconfig" ]
    then
        echo "Backing up your ~/.gitconfig file now"
        mv ~/.gitconfig ~/.gitconfig.backup.`date +%F`
        cp ~/initzsh/gitconfig ~/.gitconfig
    fi
}

function configVim(){
    if [ -f "~/.vimrc" ]
    then
        echo "Backing up your ~/.vimrc file now"
        mv ~/.vimrc ~/.vimrc.backup.`date +%F`
        cp ~/initzsh/vimrc ~/.vimrc
    fi
}

function main(){
    checkOs
    installSoftware
    downloadFile
    configZsh
    configGitconfig
    configVim
    installAutojump
}
main
