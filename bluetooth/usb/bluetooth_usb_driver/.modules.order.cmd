cmd_/home/filiplindahl/dotfiles/bluetooth/usb/bluetooth_usb_driver/modules.order := {   echo /home/filiplindahl/dotfiles/bluetooth/usb/bluetooth_usb_driver/rtk_btusb.ko; :; } | awk '!x[$$0]++' - > /home/filiplindahl/dotfiles/bluetooth/usb/bluetooth_usb_driver/modules.order
