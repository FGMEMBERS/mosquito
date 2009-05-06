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

setlistener("/sim/signals/fdm-initialized",main_loop);


aircraft.steering.init();

var logo_dialog = gui.OverlaySelector.new("Select Logo", "Aircraft/Generic/Logos", "sim/model/logo/name", nil, "sim/multiplay/generic/string");

aircraft.livery.init("Aircraft/mosquito/Models/Liveries", "sim/model/livery/name");
