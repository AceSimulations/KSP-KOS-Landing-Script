//ARC Block 3 Main Flight Computer Software (Stage 1/Boosters)
//STATUS: 1=ascent 2=Apogee, 3=PreEntry, 4=Entry Burn, 5=Passive Control, 6=Active Aero Control, 7=Landing Burn, 8=Kill velocity, 9=PostLanding Shutdown
CLEARSCREEN.  //Prep Console
//Variable Init
set driftAdjust to 0.0025.  //droneship LNG position adjustment -> used for overshoot to compensate for drag
SET WARPMODE TO "PHYSICS".  //Allow physics warp
set EntryBurn to 0. //0= Entry Burn Enabled, 1=Entry Burn Complete
set radarOffset to 0. //ALT:RADAR when landed
lock trueRadar to alt:radar - radarOffset.  // Offset radar to get distance from gear to ground
lock g to constant:g * body:mass / body:radius^2. // Gravity (m/s^2)
lock maxDecel to ((ship:availablethrust / 2) / ship:mass) - g.  // Maximum deceleration possible (m/s^2)
lock stopDist to ship:AIRSPEED^2 / (2 * maxDecel).  // The distance the burn will require
lock idealThrottle to stopDist / trueRadar. // Throttle required for perfect hoverslam
lock impactTime to trueRadar / abs(ship:verticalspeed). // Time until impact
//Flight Conditions Init
set RShut to 0. //Enables main guidance loop
set landingStart to 0.  //Enables Landing Legs deploy
Set gain to -1. //proportion for landing burn

print "Guidance V3".
SET Vehicle_Status to "Status [ 1 ]".
rcs off.
unlock steering.
sas on.
WAIT UNTIL ship:verticalspeed < -10.  //wait until decent

SET Vehicle_Status to "Status [ 2 ]".
print "Vehicle Status" at(0,20).
print Vehicle_Status at(20,20).
set target to "DroneShip".
wait .1.
//Steering Logic
lock DronePos to Target:GEOPOSITION.  //gets lat lng coordinates of the target
lock ShipPos to SHIP:GEOPOSITION.  //gets lat lng coordinates of the target
lock targetGeo TO LATLNG((DronePos:LAT),(DronePos:LNG + driftAdjust)).  //adds lng adjustment to coordinates
lock targetPos to targetGeo:POSITION. //gets vector to coordinates
lock errorVector to addons:tr:impactpos:position - targetGeo:position.  //difference between predicted landing and wanted landing
lock velVector to -ship:velocity:surface. //Literally what it says
lock result to velVector + errorVector. //Adds velocity and error to get adjustment vector
lock steer to lookdirup(result, facing:topvector).  //flies result vector with relationship to up
lock lngoff to (targetGeo:lng - addons:tr:impactpos:lng). //difference between wanted and predicted landing
lock boostbackv to (addons:tr:impactpos:position - targetGeo:position). //horizontal adjust angle for entry burn
lock line_of_sight to targetGeo:ALTITUDEPOSITION(100).
WAIT UNTIL ALT:RADAR < 90000.

SET Vehicle_Status to "Status [ 3 ]".
print "Vehicle Status" at(0,20).
print Vehicle_Status at(20,20).
SET WARP TO 0.  //stop any physics warp
set limit to 10. //limit brake movement
SHIP:PARTSDUBBED("fin")[0]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
SHIP:PARTSDUBBED("fin")[1]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
SHIP:PARTSDUBBED("fin")[2]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
SHIP:PARTSDUBBED("fin")[3]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
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
  print "Drift Adjust" at(0,19).
  print driftAdjust at(20,19).
  print "lngoff" at(0, 22).
  print lngoff at(20, 22).

  if ALT:RADAR > 2000 {
    //Entry Burn
    if ALT:RADAR < 75000 AND EntryBurn = 0 {
      until lngoff >= 0 {
        set driftAdjust to 0.002.
        LOCK STEERING TO LOOKDIRUP(ANGLEAXIS((-22),VCRS(-boostbackv,BODY:POSITION))*-boostbackv,FACING:TOPVECTOR).  //adjustment vector parallel to line between predicted and wanted landing
        SET Vehicle_Status to "Status [ 4 ]".
        AG4 off. //enables outer ring of engines
        if ALT:RADAR < 60000 {  //starts entry burn
          rcs off.
          set throt to .8.
        }
      }
      set EntryBurn to 1.
      set driftAdjust to 0.002.  
      rcs on.
    }
    else {
      AG4 off.
      if ALT:RADAR < 50000 AND ALT:RADAR > 22000 {  //no point in controlling in thin atmosphere
        set EntryBurn to 1.
        LOCK STEERING TO srfretrograde.
        set limit to 10. //stop oscillation
        SHIP:PARTSDUBBED("fin")[0]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
        SHIP:PARTSDUBBED("fin")[1]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
        SHIP:PARTSDUBBED("fin")[2]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
        SHIP:PARTSDUBBED("fin")[3]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
        SET Vehicle_Status to "Status [ 5 ]".
        rcs on.
      }
      else if ALT:RADAR > 50000 {
        rcs on.
        SET Vehicle_Status to "Status [ 3 ]".
        LOCK STEERING TO srfretrograde.
      }
      else {
        SET Vehicle_Status to "Status [ 6 ]".
        LOCK STEERING TO steer.
        if ALT:RADAR > 5000 {
          rcs off.
        }
        else {
          set driftAdjust to .0009.
          rcs on.
        }
        set limit to 50. //full aero control
        SHIP:PARTSDUBBED("fin")[0]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
        SHIP:PARTSDUBBED("fin")[1]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
        SHIP:PARTSDUBBED("fin")[2]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
        SHIP:PARTSDUBBED("fin")[3]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
      }
      SET throt TO 0.
    }
  }
  else if ALT:RADAR < 2000 AND trueRadar < stopDist { //Landing Burn
    until ALT:RADAR < 200 { //Actually doing guidance here
      print "Velocity" at(0,21).
      print ship:groundspeed at(20,21).
      print "Vehicle Status" at(0,20).
      print Vehicle_Status at(20,20).
      print "Drift Adjust" at(0,19).
      print driftAdjust at(20,19).
      print "lngoff" at(0, 22).
      print lngoff at(20, 22).
      print "gain" at(0, 23).
      print gain at(20, 23).

      if ALT:RADAR < 300 AND landingStart = 0 {  //Deploy landing legs and target ship
        Set gain to -1.
        gear on.
        AG4 off.
        set radarOffset to 36.
        set landingStart to 1.
        set driftAdjust to 0.
      }
      else {
        Set gain to -2.
        set driftAdjust to (DronePos:LNG - ShipPos:LNG) / 2.
      }
      rcs on.
      SET Vehicle_Status to "Status [ 7 ]".
      //Control Angle Calc thing
      set output to -1*ship:velocity:surface*angleAxis(1*gain*vang(line_of_sight,ship:velocity:surface),vcrs(ship:velocity:surface,line_of_sight)).
      //SET vdoutputVector TO VECDRAW(v(0,0,0),output,RGB(1,0,0),"Control",1,TRUE,0.5,TRUE).  //Draws Guidance Vector
      //SET vdoutputVector TO VECDRAW(v(0,0,0),line_of_sight,RGB(0,1,0),"LOS",1,TRUE,0.5,TRUE).  //Draws Target Vector
      //SET vdoutputVector TO VECDRAW(v(0,0,0),ship:velocity:surface,RGB(0,0,1),"Vel",1,TRUE,0.5,TRUE).  //Draws Velocity Vector
      lock steering to output.
      lock throttle to idealThrottle.
    }
    until ship:verticalspeed > -0.1 { //kill all horz and vert velocity in last 150 meters for soft landing
      SET Vehicle_Status to "Status [ 8 ]".
      lock steering to srfretrograde.
      lock throttle to idealThrottle. 
    }
    Set RShut to 1. //stop guidance
    LOCK THROTTLE TO 0.
    unlock all. //prevent errors caused by landing
  }
  else {
    set driftAdjust to (DronePos:LNG - ShipPos:LNG) / 4.
    SET Vehicle_Status to "Status [ E ]".
  }
  WAIT 0. //Run once per CPU cycle
}

SET Vehicle_Status to "Status [ 9 ]".
print Vehicle_Status at(20,20).
set limit to 10. //basically center control surfaces
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