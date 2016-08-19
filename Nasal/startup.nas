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
    if (getprop ("controls/startup/idling") ) {
      print("Startup running!");
      merlin0.magicstart();
      merlin1.magicstart();
    }
  }

}


var startup = gui.Dialog.new("/sim/gui/dialogs/startup/dialog", "Aircraft/mosquito/Dialogs/startup.xml");

setlistener("/sim/signals/fdm-initialized",init);
