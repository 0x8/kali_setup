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
    sudo apt -y install autoconf libxcb-keysyms1-dev libpango1.0-dev libxcb-util0-dev xcb libxcb1-dev libxcb-icccm4-dev libyajl-dev libev-dev libxcb-xkb-dev libxcb-cursor-dev libxkbcommon-dev libxcb-xinerama0-dev libxkbcommon-x11-dev libstartup-notification0-dev libxcb-randr0-dev libxcb-xrm0 libxcb-xrm-dev
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
    # -- Check to ensure kali didn't do something stupid like copy the service file into
    # -- /etc/systemd/system/multi-user.target.wants/open-vm-tools.service as this will
    # -- completely break the tools.
    service_loc="/etc/systemd/system/multi-user.target.wants/open-vm-tools.service"
    if [ -f $service_loc -a ! -h $service_loc ]
    then
        # -- remove the copied service and let systemd do its thing with enable
        rm $service_loc
        systemctl enable open-vm-tools.service
    fi

    # -- even more fixups for open-vm-tools as it is tremendously broken on Kali for
    # -- some reason or another
    sudo apt -y --reinstall install open-vm-tools-desktop fuse


    # Polybar
    # -- pull the latest build
    git clone --recursive https://github.com/jaagr/polybar /tmp/polybar
    # -- dependencies
    sudo apt -y install libcairo2-dev libcurl4-openssl-dev cmake python-xcbgen libpulse-dev libxcb-ewmh-dev libxcb-image0-dev xcb-proto cmake-data libiw-dev libmpdclient-dev pkg-config libasound2-dev libxcb-composite0-dev  
    # -- build & install
    mkdir /tmp/polybar/build
    cd /tmp/polybar/build
    cmake ..
    make install

}


# Apply terminal enhancements
setup_terminal () {
    
    # terminator
    # -- config taken care of during dotfile install
    sudo apt -y install terminator

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
    # -- Remove artefact installer
    rm oh-my-zsh_installer.sh

    # powerline fonts
    git clone https://github.com/powerline/fonts /tmp/powerline_fonts
    /tmp/powerline_fonts/install.sh

    # python virtualenv
    # -- download from pip
    pip install virtualenvwrapper
    # -- -- the dotfiles should take care of evaluating if the script is present
    # -- -- but if not this is an easy manual fix.

    # powerline
    # -- powerline package
    sudo pip install powerline-status
    # -- dotfiles
    git clone --single-branch --branch kali https://github.com/0x8/nptr_dotfiles ~/.nptr_dotfiles
    ~/.nptr_dotfiles/install.sh
    # -- vim (pathogen)
    mkdir -p ~/.vim/autoload ~/.vim/bundle && \
    curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
    # -- tmux
    sudo apt -y install tmux
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

nptr_dotfile_fixups () {
# This section handles the editing of dotfiles from my dotfile dir
# (https://github.com/0x8/nptr_dotfiles) downloaded in setup_terminal.
# This section ensures that the lines that will be commented out during
# the dotfile installer, be uncommented as the dependencies should be fulfilled
# by this script

# VIM
# uncomment vim pathogen
sed -i s/\"execute pathogen/execute pathogen/g $HOME/.vimrc

# TMUX
# lines tokens should simply be "run-shell \"powerline" and
# "source /usr/local/lib/python"
sed -i "s@\#run-shell \"pow@run-shell \"pow/g" ~/.tmux.conf
sed -i "s@\#source /usr/local/lib/python@source /usr/local/lib/python/g" ~/.tmux.conf

}

# Run the commands
setup_terminal
setup_environment
nptr_dotfile_fixups

# Fix ssh when using a NAT'd network interface (Default in VMWare)
# openssh created a breaking change a few months back but luckily
# the fix is fairly simple
if [ -f "$HOME/.ssh/config" ]
then
    # Append to existing, add a blank buffer line for clarity
    echo "" >> "$HOME/.ssh/config"
fi
echo "Host *" >> "$HOME/.ssh/config"
echo "    IPQoS lowdelay throughput" >> "$HOME/.ssh/config"

# Run updates (This takes an EXTREMELY long time if being done for the first time
sudo apt -y upgrade && sudo apt -y dist-upgrade

