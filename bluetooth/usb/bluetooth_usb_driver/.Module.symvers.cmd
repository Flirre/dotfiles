cmd_/home/filiplindahl/dotfiles/bluetooth/usb/bluetooth_usb_driver/Module.symvers := sed 's/\.ko$$/\.o/' /home/filiplindahl/dotfiles/bluetooth/usb/bluetooth_usb_driver/modules.order | scripts/mod/modpost  -a  -o /home/filiplindahl/dotfiles/bluetooth/usb/bluetooth_usb_driver/Module.symvers -e -i Module.symvers  -N -T -
