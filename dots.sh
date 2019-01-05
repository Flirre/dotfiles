#!/usr/bin/env bash
if [ "${XDG_CURRENT_DESKTOP}" == "i3" ]; then
       (cp -r /home/$USER/.config/i3/ ./ && echo "Successfully backed up i3 config.") || echo "i3 backup failed."
fi
(cp /home/$USER/.config/compton.conf ./ && echo "Successfully backed up Compton config.") || echo "Compton backup failed."
(cp -r /home/$USER/.config/polybar/ ./ && echo "Successfully backed up Polybar config.") || echo "Polybar backup failed."
(cp -r /home/$USER/.config/kitty/ ./ && echo "Successfully backed up KiTTy config.") || echo "KiTTy backup failed."
(cp -r /home/$USER/.config/fish/ ./ && echo "Successfully backed up fish config.") || echo "fish backup failed."
