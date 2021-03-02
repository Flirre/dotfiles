#!/usr/bin/env fish

function update
    sudo pacman -Syu; and yay
end
