#!/usr/bin/env fish

if test -d ~/.doom.d
    echo "DOOM Emacs personal configuration already set up"
else
    echo "Cloning personal configuration.."
    git clone git@github.com:Flirre/.doom.d.git ~/.doom.d
    and echo \n"Successfully cloned personal configuration"\n\n
    or echo \n"Failed to clone personal configuration"\n\n
end

if test -d ~/.emacs.d
    echo "DOOM Emacs is already downloaded"
else
    echo "Cloning DOOM Emacs.."
    git clone --depth 1 https://github.com/hlissner/doom-emacs ~/.emacs.d
    and echo "Successfully cloned DOOM Emacs"\n\n
    or echo "Failed to clone DOOM Emacs"\n\n
end

if not test -d ~/.emacs.d/.local/straight
    echo "Installing DOOM Emacs.."
    ~/.emacs.d/bin/doom install
    and echo "Successfully installed DOOM Emacs"\n\n
    or echo "Failed to install DOOM Emacs"\n\n
    echo "Compiling DOOM Emacs.."
    ~/.emacs.d/bin/doom compile
    and "Successfully compiled DOOM Emacs"\n\n
    or echo "failed to compile DOOM Emacs"\n\n
else
    echo "DOOM Emacs already installed"
end

# Add doom to path if not already added.
if not contains /home/*/.emacs.d/bin $fish_user_paths
    echo "Adding DOOM to user path"
    set -Ua fish_user_paths ~/.emacs.d/bin
else
    echo "DOOM Emacs already present on path"
end
