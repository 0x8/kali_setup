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
    # -- build i3-gaps
    cd /tmp/i3-gaps
    autoreconf --force --install
    rm -rf build/
    mkdir -p build && cd build/
    ../configure --prefix=/usr --sysconfdir=/etc --disable-sanitizers
    make
    sudo make install
    # -- install missing dmenu
    sudo apt install dmenu

    # if i3_exlcusive is true, get rid of gnome
    if $i3_exclusive
    then    
        sudo apt remove gnome
    fi

}


# Apply terminal enhancements
setup_terminal () {
    
    # zsh
    sudo apt install zsh

    # oh-my-zsh
    sh -c "$(curl -fsSL https://githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

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
    sudo apt install tmux
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
    sed -i "s/\"execute pathogen#infect()/execute pathogen#infect()" $HOME/.vimrc 
    
}


# Run the commands
setup_terminal
setup_environment
