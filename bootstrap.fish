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
