#!/bin/bash

# @author: Ian Guibas
# Kali environment setup script intended to create a more
# full-featured, dev-friendly environment for those of us
# who prefer never touching the mouse. Naturally I can't do
# anything about the non-terminal based tools, this script simply
# applies a number of improvements to the system environment while
# in a terminal.


# i3_exclusive, when set to true, will rid the system of gnome.
# Only set this to true if you know what you are doing.
i3_exclusive=false

# Environment Setup
setup_environment () {

    # Download i3-gaps
    git clone https://github.com/airblader/i3 /tmp/i3-gaps
    # -- install i3-gaps dependencies
    sudo apt -y install libxcb-keysyms1-dev libpango1.0-dev libxcb-util0-dev xcb libxcb1-dev libxcb-icccm4-dev libyajl-dev libev-dev libxcb-xkb-dev libxcb-cursor-dev libxkbcommon-dev libxcb-xinerama0-dev libxkbcommon-x11-dev libstartup-notification0-dev libxcb-randr0-dev libxcb-xrm0 libxcb-xrm-dev
    # -- build i3-gaps
    cd /tmp/i3-gaps
    autoreconf --force --install
    rm -rf build/
    mkdir -p build && cd build/
    ../configure --prefix=/usr --sysconfdir=/etc --disable-sanitizers
    make
    sudo make install
    # -- install missing dmenu
    sudo apt -y install dmenu

    # if i3_exlcusive is true, get rid of gnome
    if $i3_exclusive
    then    
        sudo apt remove gnome
    fi

    sudo apt -y install i3status

    # Install vmware tools for proper display
    sudo apt -y install open-vm-tools
    # -- fix broken service script
    # -- The default open-vm-tools service is broken for some odd reason
    # -- requiring the addition of the following edit to scale properly at boot
    sed -i '/\[Unit\]/a After=graphical.target' /etc/systemd/system/multi-user.target.wants/open-vm-tools.service

}


# Apply terminal enhancements
setup_terminal () {
    
    # zsh
    sudo apt -y install zsh

    # oh-my-zsh
    # -- The installation file is pulled and edited to make it not
    # -- annoyingly switch environments at the end and de-rail this
    # -- script.
    # -- Pull the installer script (it downloads oh-my-zsh)
    curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh > oh-my-zsh_installer.sh
    chmod +x oh-my-zsh_installer.sh
    sed -i "s/env zsh -l//g" oh-my-zsh_installer.sh
    ./oh-my-zsh_installer.sh

    # powerline fonts
    git clone https://github.com/powerline/fonts /tmp/powerline_fonts
    /tmp/powerline_fonts/install.sh

    # python virtualenv
    # -- download from pip
    pip install virtualenvwrapper
    # -- -- the dotfiles should take care of evaluating if the script is present
    # -- -- if not this is an easy manual fix.

    # powerline
    # -- dotfiles
    git clone https://github.com/0x8/nptr_dotfiles ~/.nptr_dotfiles
    ~/.nptr_dotfiles/install.sh
    # -- vim (pathogen)
    mkdir -p ~/.vim/autoload ~/.vim/bundle && \
    curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
    # -- tmux
    sudo apt -y install tmux
    # -- powerline package
    sudo pip install powerline-status
    powerline_dir=$(pip show powerline-status | grep Location | cut -d" " -f2)/powerline
    if [ ! -d $HOME/.vim/bundle ]
    then
        mkdir -p $HOME/.vim/bundle
    fi
    # -- -- [ ln -s SOURCE TARGET ]
    # -- -- This should HOPEFULLY work here without much fuss
    ln -s $powerline_dir/bindings/vim $HOME/.vim/bundle/powerline
    # -- check and fix up .vimrc
    sed -i "s/\"execute pathogen#infect()/execute pathogen#infect()/g" $HOME/.vimrc 
    
}


# Run the commands
setup_terminal
setup_environment
