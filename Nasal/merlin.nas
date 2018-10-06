var looptime = 0.2;
var airspeed = props.globals.getNode("velocities/airspeed-kt");
var envtemp = props.globals.getNode("environment/temperature-degc");
var gload = props.globals.getNode("accelerations/pilot-g",1);
var alt = props.globals.getNode("instrumentation/altimeter/pressure-alt-ft");
var ambient_pressure = props.globals.getNode ("/environment/pressure-inhg");

var mp_max = 62.50;
var mp_idle = 3;
var blowershiftalt = 6000;
var lowblower = 0.693;
var highblower = 1;
var rpm_max = 3100;

var merlin66 = {
   new : func (engine_number) {
      var m = { parents: [merlin66] };
      m.engine = props.globals.getNode("engines/engine[" ~ engine_number ~ "]");
      m.carbetemp = m.engine.getNode ("carburettor-entry-temp-degc", 1);
      m.crankloop = m.engine.getNode ("crankloop");
      m.cyltemp = m.engine.getNode ("cylinder-temp-degc");
      m.engcrank = m.engine.getNode ("cranking");
      m.exhtempf = m.engine.getNode ("egt-degf");
      m.manpress = m.engine.getNode ("mp-osi");
      m.nofuel = m.engine.getNode ("out-of-fuel",1 );
      m.oilpress = m.engine.getNode ("oil-press", 1);
      m.oiltemp = m.engine.getNode ("oil-temperature-degf");
      m.oiltempcalc = m.engine.getNode ("oil-temperature-calc", 1);
      m.overrev = m.engine.getNode ("overrev", 1);
      m.primed = m.engine.getNode ("primed");
      m.rpm = m.engine.getNode ("rpm");
      m.rstrain = m.engine.getNode ("rev-strain");
      m.running = m.engine.getNode ("running");
      m.startup = m.engine.getNode ("startup", 1);
      m.startup_smoke = m.engine.getNode ("startup-smoke", 1);
      m.thrust = m.engine.getNode ("thrust-lbs",1);
      m.viscosity = m.engine.getNode ("oil-visc");

      m.controls = props.globals.getNode("controls/engines/engine[" ~ engine_number ~ "]");
      m.boost = m.controls.getNode ("boost");
      m.coolflap_auto = m.controls.getNode("coolflap-auto", 1);
      m.cowlflap = m.controls.getNode ("cowl-flaps-norm", 1);
      m.magnetos = m.controls.getNode("magnetos");
      m.mixture = m.controls.getNode ("mixture");
      m.mixture0 = m.controls.getNode ("mixture0", 1);
      m.propeller_pitch = m.controls.getNode("propeller-pitch");
      m.prop_auto = m.controls.getNode ("prop-auto", 1);
      m.radlever = m.controls.getNode("radlever", 1);
      m.throttle = m.controls.getNode ("throttle");
      m.throttle_c = m.controls.getNode ("throttle-c", 1);

      m.tank = [
         props.globals.getNode ("consumables/fuel/tank[" ~ (engine_number)   ~ "]/selected"),
         props.globals.getNode ("consumables/fuel/tank[" ~ (engine_number+2) ~ "]/selected"),
         props.globals.getNode ("consumables/fuel/tank[" ~ (engine_number+4) ~ "]/selected") ];

      if (engine_number == 0) m.name = "Port engine";
      else if (engine_number == 1) m.name = "Starboard engine";
      m.loop_timer = nil;

      # initialize
      m.cyltemp.setDoubleValue (envtemp.getValue());
      m.prop_auto.setBoolValue(0);
      return m;
   },

   engine_update : func () {
      # if someone has suggestions to calculate engine parameters more realistic drop me a note
      var as = airspeed.getValue();
      var cf = me.cowlflap.getValue();
      var ct = me.cyltemp.getValue();
      var et0 = envtemp.getValue();
      var egt = me.exhtempf.getValue();
      var rs = me.rstrain.getValue();
      var thr = me.thrust.getValue();
      var rpm0 = me.rpm.getValue();
      var mp = me.manpress.getValue();
      var mix = me.mixture.getValue();
      # calculate carburettor entry temperature
      var cat = et0 + 0.6 * mp;
      #print ("CET: ",cat);
      me.carbetemp.setValue(cat);
      # summing up various parameters with a weighing factor
      var temp = 3 * cat + 0.3 * rpm0 + 0.5 * egt - 0.005 * as * as - 0.07* thr * (cf+0.1) -20 * mix;
      #print ("Temp: ",temp,"Mix: ",mix);
      me.cyltemp.setDoubleValue (temp * 0.4);

      # Automatic mixture control.  Mixture is 1 up to 3600 ft (ambient pressure for a standard
      # atmosphere=26.3296 inHg) then decreases in proportion to ambient pressure.
      var amb = ambient_pressure.getValue();
      me.mixture.setValue (math.min (1.0, amb / 26.3296));

      # adjust throttle
      var throttle_s = me.throttle.getValue() * mp_max;
      if (me.throttle_c.getValue() > 1) {
         me.throttle_c.setValue(1);
      }
      if (me.throttle_c.getValue() < 0) {
         me.throttle_c.setValue(0);
      }
      var xx = me.throttle_c.getValue() + ((throttle_s - mp) * 0.0015);
      me.throttle_c.setValue (xx);
   },

   fluid_update : func () {
      var otemp = me.oiltemp.getValue();
      var visc = me.viscosity.getValue();
      # print (otemp," ",visc);
      me.oilpress.setValue (8.2 - 2*visc);
      me.oiltempcalc.setValue (otemp * visc - 70);
      if (visc < 1.0 ) {
         me.viscosity.setValue (visc + 0.002);
      }
   },

   check_engine : func () {
      var rs = me.rstrain.getValue();
      var rpm0 = me.rpm.getValue();
      var mp = me.manpress.getValue();
      if (me.startup.getBoolValue()) {
         # print ("startup!");
         me.startup_smoke.setBoolValue (1);
         me.startup.setBoolValue (0);
         settimer (func { me.startup_smoke.setBoolValue (0) }, 3);
      }
      #check for overrev
      if (rpm0 > rpm_max) {
         var rs0 = 0.01 * (rpm0 - rpm_max) * (rpm0 - rpm_max);
         me.rstrain.setValue (rs + rs0);
         # print (rs0, " ",rs + rs0);
      }
      if (me.rstrain.getValue () > 300000 ) {
         me.overrev.setBoolValue(1);
         failure.kill_engine();
      }
      if (gload.getValue() < -0.3 ) {
         print ("cutout!");
         setprop ("sim/messages/copilot", me.name ~ " starved of fuel by negative G-force!");
         if (me.mixture0.getValue() == 0) {
            me.mixture0.setValue (me.mixture.getValue());
            me.mixture.setValue(0);
         }
      }
      else if (me.mixture0.getValue() != 0 ) {
         me.mixture.setValue (me.mixture0.getValue());
         me.mixture0.setValue(0);
      }
   },

   set_prop : func () {
      if (me.prop_auto.getBoolValue()) {
         var ppitch = me.propeller_pitch.getValue();
         mpress = me.manpress.getValue();
         if (me.rpm.getValue() / mpress < 55.0)  {
            me.propeller_pitch.setDoubleValue (ppitch + 0.003);
         }
         if (me.rpm.getValue() / mpress > 55.0)  {
            me.propeller_pitch.setDoubleValue (ppitch - 0.003);
         }
      }
   },

   set_boost : func () {
      if (alt.getValue () > blowershiftalt) {
         me.boost.setValue(highblower);
      }
      if (alt.getValue () < blowershiftalt) {
         me.boost.setValue(lowblower);
      }
   },

   check_startup : func () {
      if (me.running.getValue() == 0) {
         me.crankloop.setValue (me.rpm.getValue() * 0.008);
         if (me.crankloop.getValue () > 1) {
            me.crankloop.setValue (0);
         }
         # print (" engine off");
         if (me.engcrank.getValue()) {
            # print (" commencing startup");
            if (me.rpm.getValue() >= 200 and me.primed.getValue() >= 1) {
               me.nofuel.setAttribute("writable", 1);
               me.startup.setBoolValue (1);
            }
         } else {
            # print ("no startup");
            me.startup.setBoolValue (0);
         }
      }
   },

   main_loop : func () {
      if (me.running.getValue() == 1) {
         me.engine_update();
         me.fluid_update();
         me.check_engine();
         me.set_prop();
         me.set_boost();
      } else {
         me.nofuel.setAttribute("writable",0);
         me.check_startup();
      }
   },

   init : func () {
      if (getprop("/controls/startup/idling") == 1) {
         me.tank[0].setBoolValue(1);
         me.tank[1].setBoolValue(1);
         me.tank[2].setBoolValue(0);
         me.magnetos.setValue(3);
         me.coolflap_auto.setBoolValue(1);
         me.radlever.setBoolValue(1);
         me.propeller_pitch.setValue(1.0);
         me.viscosity.setValue(1.0);
         me.rpm.setValue(800.0);
         me.running.setBoolValue(1);
         me.nofuel.setAttribute("writable",1);
         me.nofuel.setBoolValue(0);
      } else {
         me.nofuel.setAttribute("writable",0);
      }
      if (me.loop_timer == nil) {
         me.loop_timer = maketimer (looptime, me, me.main_loop);
         me.loop_timer.start();
      }
   }
};

var port_engine = merlin66.new (0);
var starboard_engine = merlin66.new (1);
