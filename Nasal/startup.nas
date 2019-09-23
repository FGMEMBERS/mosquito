var init =func () {
  if (getprop ("controls/startup/config")) {
    print ("Config Startup");

    # pausing FG
    setprop("/sim/freeze/master", 1);
    setprop("/sim/freeze/clock", 1);

    # zero out controls
    setprop("controls/flight/aileron",0);
    setprop("controls/flight/elevator",0);
    setprop("controls/flight/rudder",0);

    #open dialog
    startup.open();
  } else {
    mosquito.port_engine.init();
    mosquito.starboard_engine.init();
  }
}


var startup = gui.Dialog.new("/sim/gui/dialogs/startup/dialog", "Aircraft/mosquito/Dialogs/startup.xml");

setlistener("/sim/signals/fdm-initialized",init);
