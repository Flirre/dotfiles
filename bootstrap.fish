#!/bin/fish
#Setup Oh My Fish!
curl -L https://get.oh-my.fish | fish

# Setup Fisher
curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher

# fuzzy finder, ctrl+r to fuzz
omf install https://github.com/jethrokuan/fzf

# git aliases galore
omf install https://github.com/jhillyerd/plugin-git

# fish.nvm
fisher install jorgebucaran/nvm.fish

# use nvm to install latest node version for
# local user package installations without sudo
nvm install latest

# and set it as default nvm version for all following shells
set --universal nvm_default_version latest
