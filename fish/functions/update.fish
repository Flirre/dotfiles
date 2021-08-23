#!/usr/bin/env fish

function update
    sudo pacman -Syu; and paru
end
