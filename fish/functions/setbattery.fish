# Defined in - @ line 0
function setbattery --description 'alias setbattery=sudo tpacpi-bat -s ST 0 40 ; sudo tpacpi-bat -s SP 0 80'
	sudo tpacpi-bat -s ST 0 40 ; sudo tpacpi-bat -s SP 0 80 $argv;
end
