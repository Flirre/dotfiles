#!/usr/bin/env fish

complete -c setup_computer -x -a "-a -all -b --base -h --home -w --work"
function setup_computer
    function permitted_flags
        echo "Permitted flags:
    -a/--all
    -b/--base
    -h/--home
    -w/--work"
        functions -e permitted_flags
    end

    if test (count $argv) -eq 1
        set -l arg $argv[1]
        switch "$arg"
            case -a --all
                sudo pacman -S - <~/dotfiles/packages/base
                paru -S - <~/dotfiles/packages/base
                sudo pacman -S - <~/dotfiles/packages/home
                paru -S - <~/dotfiles/packages/home
                sudo pacman -S - <~/dotfiles/packages/work
                paru -S - <~/dotfiles/packages/work
            case -b --base
                sudo pacman -S - <~/dotfiles/packages/base
                paru -S - <~/dotfiles/packages/base-aur
            case -h --home
                paru -S - <~/dotfiles/packages/home
            case -w --work
                paru -S - <~/dotfiles/packages/work
            case '*'
                permitted_flags
        end
    else
        permitted_flags
    end
end
