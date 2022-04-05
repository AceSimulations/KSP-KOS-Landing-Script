//ARC Block 3 Main Flight Computer Software (Stage 1/Boosters)
//STATUS: 1=ascent 2=Apogee, 3=PreEntry, 4=Entry Burn, 5=Passive Control, 6=Active Aero Control, 7=Landing Burn, 8=PostLanding Shutdown
CLEARSCREEN.  //Prep Console
//Variable Init
set driftAdjust to 0.0025.  //droneship LNG position adjustment -> used for overshoot to compensate for drag
SET WARPMODE TO "PHYSICS".  //Allow physics warp
set EntryBurn to 0. //0= Entry Burn Enabled, 1=Entry Burn Complete
set radarOffset to 0. //ALT:RADAR when landed
lock trueRadar to alt:radar - radarOffset.  // Offset radar to get distance from gear to ground
lock g to constant:g * body:mass / body:radius^2. // Gravity (m/s^2)
lock maxDecel to (ship:availablethrust / ship:mass) - g.  // Maximum deceleration possible (m/s^2)
lock stopDist to ship:AIRSPEED^2 / (2 * maxDecel).  // The distance the burn will require
lock idealThrottle to stopDist / trueRadar. // Throttle required for perfect hoverslam
lock impactTime to trueRadar / abs(ship:verticalspeed). // Time until impact

//Flight Conditions Init
set RShut to 0. //Enables main guidance loop
set landingStart to 0.  //Enables Landing Legs deploy

//Steering Logic
lock errorVector to addons:tr:impactpos:position - targetGeo:position.  //difference between predicted landing and wanted landing
lock velVector to -ship:velocity:surface. //Literally what it says
lock result to velVector + errorVector. //Adds velocity and error to get adjustment vector
lock steer to lookdirup(result, facing:topvector).  //flies result vector with relationship to up
lock lngoff to (targetGeo:lng - addons:tr:impactpos:lng). //difference between wanted and predicted landing

SET Vehicle_Status to "Status [ 1 ]".
WAIT UNTIL ship:verticalspeed < -10.  //wait until decent

SET Vehicle_Status to "Status [ 2 ]".
print "Vehicle Status" at(0,20).
print Vehicle_Status at(20,20).
set target to "DroneShip".
wait .1.
lock DronePos to Target:GEOPOSITION.  //gets lat lng coordinates of the target
lock targetGeo TO LATLNG((DronePos:LAT),DronePos:LNG + driftAdjust).  //adds lng adjustment to coordinates
lock targetPos to targetGeo:POSITION. //gets vector to coordinates
sas off.
rcs off.
WAIT UNTIL ALT:RADAR < 90000.

SET Vehicle_Status to "Status [ 3 ]".
print "Vehicle Status" at(0,22).
print Vehicle_Status at(0,23).
SET WARP TO 0.  //stop any physics warp
AG7 on. //deploy brakes
rcs on.
sas off.
Lights on.
set throt to 0.
LOCK THROTTLE TO throt.
lock steering to srfretrograde. //steer to velocity vector -> AKA flamy end down

//Transfer Fuel
print "Transfering Fuel".
SET header to SHIP:PARTSDUBBED("Header").
SET central to SHIP:PARTSDUBBED("Central").
SET lower to SHIP:PARTSDUBBED("Lower").
SET base to SHIP:PARTSDUBBED("Base").
print "Fuel Transfer Start".
wait .1.
SET LF1 TO TRANSFERALL("LqdMethane", header, central).
SET LF2 TO TRANSFERALL("LqdMethane", central, lower).
SET LF3 TO TRANSFERALL("LqdMethane", lower, base).
wait .1.
print "Liguid Fuel Transfer Nominal".
SET LF1:ACTIVE to TRUE.
SET LF2:ACTIVE to TRUE.
SET LF3:ACTIVE to TRUE.
print "Liguid Fuel Transfer Complete".
wait .1.
SET OX1 TO TRANSFERALL("OXIDIZER", header, central).
SET OX2 TO TRANSFERALL("OXIDIZER", central, lower).
SET OX3 TO TRANSFERALL("OXIDIZER", lower, base).
print "Oxidizer Fuel Transfer Nominal".
wait .1.
SET OX1:ACTIVE to TRUE.
SET OX2:ACTIVE to TRUE.
SET OX3:ACTIVE to TRUE.
print "Oxidizer Fuel Transfer Complete".

UNTIL RShut = 1 { //Main Flight Control Loop
  print "Velocity" at(0,21).
  print ship:groundspeed at(20,21).
  print "Vehicle Status" at(0,20).
  print Vehicle_Status at(20,20).

  if ALT:RADAR > 5800 {
    //Entry Burn
    if ALT:RADAR < 70000 AND SHIP:AIRSPEED > 1000 AND EntryBurn = 0 {
      until lngoff >= 0 {
        set driftAdjust to 0.03.
        LOCK STEERING TO LOOKDIRUP(ANGLEAXIS((-15),VCRS(-boostbackv,BODY:POSITION))*-boostbackv,FACING:TOPVECTOR).  //adjustment vector parallel to line between predicted and wanted landing
        SET Vehicle_Status to "Status [ 4 ]".
        AG4 on. //enables outer ring of engines
        set limit to 50.  //give me all the controllll
        SHIP:PARTSDUBBED("fin")[0]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
        SHIP:PARTSDUBBED("fin")[1]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
        SHIP:PARTSDUBBED("fin")[2]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
        SHIP:PARTSDUBBED("fin")[3]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
        if ALT:RADAR < 55000 {  //starts entry burn
          rcs off.
          set throt to .8.
        }
      }
    }
    if SHIP:AIRSPEED < 1500 AND ALT:RADAR < 55000 AND EntryBurn = 0 { //continues entry burn
      AG4 off.  //shuts down outer ring
      rcs on.
      set throt to .8.
      set driftAdjust to 0.003. //entry burn overshoot .003
      until lngoff >= 0 { //adjust until error is basically gone
        LOCK STEERING TO LOOKDIRUP(ANGLEAXIS((-30),VCRS(-boostbackv,BODY:POSITION))*-boostbackv,FACING:TOPVECTOR).  
      }
      set EntryBurn to 1.
      set driftAdjust to 0.001.
    }
    else {
      AG4 off.
      if ALT:RADAR < 53000 AND ALT:RADAR > 40000 {  //no point in controlling in thin atmosphere
        set EntryBurn to 1.
        LOCK STEERING TO srfretrograde.
        SET Vehicle_Status to "Status [ 5 ]".
        rcs on.
      }
      else {
        SET Vehicle_Status to "Status [ 6 ]".
        LOCK STEERING TO steer.
        rcs off.
      }
      SET throt TO 0.
    }
  }
  else if ALT:RADAR < 5800 AND trueRadar < stopDist { //Landing Burn
    until ALT:RADAR < 150 { //Actually doing guidance here
      print "Vehicle Status" at(0,20).
      print Vehicle_Status at(20,20).
      Set line_of_sight to target:position - ship:position.
      if ALT:RADAR < 500 {  //Deploy landing legs
        if landingStart = 0 {
          set driftAdjust to 0.
          gear on.
          AG4 off.
          set radarOffset to 36.
        }
        set landingStart to 1.
        if lngoff < .001 {
          set output to -1*ship:velocity:surface*angleAxis(gain*vang(line_of_sight,ship:velocity:surface),vcrs(ship:velocity:surface,line_of_sight)).
          Set gain to -3.
          SET Vehicle_Status to "Status [7.3]".
        }
        else {
          set output to 1*ship:velocity:surface*angleAxis(gain*vang(line_of_sight,up:vector),vcrs(up:vector,line_of_sight)).
          Set gain to 2.
          SET Vehicle_Status to "Status [7.4]".
        }
        lock steering to output.
      }
      else {  //landing burn states => ADJUSTING OVERSHOOT AMOUNT
        if ALT:RADAR < 3500 AND ALT:RADAR > 2500 {
          set driftAdjust to 0.0005.
        }
        else if ALT:RADAR < 2500 AND ALT:RADAR > 1500 {
          set driftAdjust to 0.0003.
        }
        else if ALT:RADAR < 1500 {
          set driftAdjust to 0.0001.
        }
        else if ALT:RADAR < 1000 {
          set driftAdjust to 0.
        }
        else {
          set driftAdjust to 0.001.
        }
        if lngoff < .001 { //slow horz speed
          set output to -1*ship:velocity:surface*angleAxis(gain*vang(line_of_sight,ship:velocity:surface),vcrs(ship:velocity:surface,line_of_sight)).
          Set gain to 11 - (idealThrottle/-10).  //throttling verticle thrust vector with angle to try and use full thrust
          SET Vehicle_Status to "Status [7.1]".
        }
        else {  //pitch up from undershooting
          SET Vehicle_Status to "Status [7.2]".
          set output to -1*ship:velocity:surface*angleAxis(gain*vang(line_of_sight,ship:velocity:surface),vcrs(ship:velocity:surface,line_of_sight)).
          Set gain to (idealThrottle/-10).  //throttling verticle thrust vector with angle to try and use full thrust
        }
      }
      lock steering to output.
      lock throttle to idealThrottle.
      //SET vdoutputVector TO VECDRAW(v(0,0,0),output,RGB(0,0,1),"Control",1,TRUE,0.1,TRUE).  //Draws Guidance Vector for landing
    }
    until ship:verticalspeed > -0.1 { //kill all horz and vert velocity in last 150 meters for soft landing
      SET Vehicle_Status to "Status [7.5]".
      lock steering to srfretrograde.
      lock throttle to idealThrottle. 
    }
    Set RShut to 1. //stop guidance
    LOCK THROTTLE TO 0.
    unlock all. //prevent errors caused by landing
  }
  WAIT 0. //Run once per CPU cycle
}

SET Vehicle_Status to "Status [ 8 ]".
print Vehicle_Status at(20,20).
set limit to 5. //basically center control surfaces
SHIP:PARTSDUBBED("fin")[0]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
SHIP:PARTSDUBBED("fin")[1]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
SHIP:PARTSDUBBED("fin")[2]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
SHIP:PARTSDUBBED("fin")[3]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
rcs on.
lock steering to up.  //try and stablize rocket
LOCK THROTTLE TO 0.
WAIT 5.
sas off.
UNLOCK STEERING.
AG7 off.
rcs off.
lights off.
unlock throttle.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.  //set main throttle to 0 so you don't try taking off again
SHUTDOWN. //shutdown flight computer