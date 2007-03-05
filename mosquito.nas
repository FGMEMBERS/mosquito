init = func {
  setprop ("/autopilot/locks/heading" , "none" );
  setprop ("/autopilot/locks/altitude" , "none" );
 main_loop();
}


main_loop = func {
  cview = getprop("/sim/current-view/view-number");
    if (cview == 6) {
      aphmode = getprop ("/autopilot/locks/heading");
      apvmode = getprop ("/autopilot/locks/altitude");
      if (aphmode == "none" ) {
        setprop ("/autopilot/locks/heading", "wing-leveler");
        setprop ("/autopilot/htempmode", 1 );
      }
      if (apvmode == "none" ) {
        setprop ("/autopilot/locks/altitude", "vertical-speed-hold");
        setprop ("autopilot/vtempmode" , 1 );
      }

    } else {
      htempmode = getprop ("/autopilot/htempmode");
      vtempmode = getprop ("/autopilot/vtempmode");
      if (htempmode == 1) {
        setprop ("/autopilot/locks/heading" , "none" );
        setprop ("/autopilot/htempmode" , 0);
      }
      if (vtempmode == 1) {
        setprop ("/autopilot/locks/altitude" , "none" );
        setprop ("/autopilot/vtempmode" , 0);
      }
    }
    settimer(main_loop, 0.5);
} 


toggle_door = func {
  canopy = aircraft.door.new ("/controls/doors/door/",3);
  if(getprop("//controls/doors/door/position-norm") > 0) {
      canopy.close();
  } else {

      canopy.open();
  }
}



fuel_jettison = func(side) {
  remaining_inner = getprop("consumables/fuel/tank["~side~"]/level-gal_us");
  remaining_outer = getprop("consumables/fuel/tank["~(side+1)~"]/level-gal_us");
  interpolate("consumables/fuel/tank["~side~"]/level-gal_us", (remaining_inner-20),5);
  interpolate("consumables/fuel/tank["~(side+1)~"]/level-gal_us", (remaining_outer-15),5);
}

toggle_cowlflaps = func {
  if(getprop("/controls/engines/engine[0]/cowl-flaps-norm") > 0) {
    interpolate("/controls/engines/engine[0]/cowl-flaps-norm", 0, 3);
  } else {
    interpolate("/controls/engines/engine[0]/cowl-flaps-norm", 1, 3);
  }
}


