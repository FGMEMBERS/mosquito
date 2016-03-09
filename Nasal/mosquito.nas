var alt = props.globals.getNode("instrumentation/altimeter/pressure-alt-ft");
var boost0 = props.globals.getNode("controls/engines/engine[0]/boost");
var blower0 = props.globals.getNode("controls/engines/engine[0]/blower");
var boost1 = props.globals.getNode("controls/engines/engine[1]/boost");
var blower1 = props.globals.getNode("controls/engines/engine[1]/blower");
var lowblower = 0.45;

#### Set boost level
var main_loop = func {

	if (alt.getValue() > 13700 and blower0.getValue() == 0 ) {
		interpolate (boost0, 1,30);
		blower0.setValue(1);
		}
	if (alt.getValue() < 13700 and blower0.getValue() == 1 ) {
		interpolate (boost0, lowblower,30);
		blower0.setValue(0);
		}
	if (alt.getValue() > 13700 and blower1.getValue() == 0 ) {
		interpolate (boost1, 1,30);
		blower1.setValue(1);
		}
	if (alt.getValue() < 13700 and blower1.getValue() == 1 ) {
		interpolate (boost1, lowblower,30);
		blower1.setValue(0);
		}
  settimer(main_loop, 0.2)
}

var switch_fuelS = func {
  cockR = getprop ("controls/fuel/stbdcock");
  setprop ("consumables/fuel/tank[1]/selected", 0);
  setprop ("consumables/fuel/tank[3]/selected", 0);
  setprop ("consumables/fuel/tank[5]/selected", 0);

  # inner tanks
  if ( cockR == 1 ) {
    setprop ("consumables/fuel/tank[1]/selected", 1);
    setprop ("consumables/fuel/tank[3]/selected", 1);
  }
  # outer tanks
  if ( cockR == 2 ) {
    setprop ("consumables/fuel/tank[5]/selected", 1);
  }
}

var switch_fuelP = func {
  cockL = getprop ("controls/fuel/prtcock");
  setprop ("consumables/fuel/tank[0]/selected", 0);
  setprop ("consumables/fuel/tank[2]/selected", 0);
  setprop ("consumables/fuel/tank[4]/selected", 0);

  # inner tanks
  if ( cockL == 1 ) {
    setprop ("consumables/fuel/tank[0]/selected", 1);
    setprop ("consumables/fuel/tank[2]/selected", 1);
  }
  # outer tanks
  if ( cockL == 2 ) {
    setprop ("consumables/fuel/tank[4]/selected", 1);
  }
}

setlistener("/sim/signals/fdm-initialized",main_loop);

aircraft.steering.init();

var door = aircraft.door.new ("/controls/doors/door/",2.5);

var bombbaydoor = aircraft.door.new ("/controls/armament/bombbaydoor/",3.5);

aircraft.livery.init("Aircraft/mosquito/Models/Liveries", "sim/model/livery/name");

var config = gui.Dialog.new("/sim/gui/dialogs/appearance/dialog", "Aircraft/mosquito/Dialogs/config.xml");

var flash_trigger = props.globals.getNode("sim/armament/gun[0]/fire", 0);
aircraft.light.new("sim/model/mosquito/lighting/flash-l", [0.03, 0.02], flash_trigger);
aircraft.light.new("sim/model/mosquito/lighting/flash-r", [0.024, 0.03], flash_trigger);
