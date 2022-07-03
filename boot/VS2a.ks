//ARC Block 3.1 Main Flight Computer Software (Stage 1/Boosters)
//STATUS: 1=ascent 2=Apogee, 3=PreEntry, 4=Entry Burn, 5=Passive Control, 6=Active Aero Control, 7=Landing Burn, 8=Kill velocity, 9=PostLanding Shutdown
wait until ship:verticalspeed < -10.
CLEARSCREEN.  //Prep Console
//Variable Init
SET WARPMODE TO "PHYSICS".  //Allow physics warp
set EntryBurn to 0. //0= Entry Burn Enabled, 1=Entry Burn Complete
set radarOffset to -50. //ALT:RADAR when landed
lock trueRadar to alt:radar - radarOffset.  // Offset radar to get distance from gear to ground
lock g to constant:g * body:mass / body:radius^2. // Gravity (m/s^2)
lock maxDecel to (ship:availablethrust / ship:mass) - g.  // Maximum deceleration possible (m/s^2)
lock stopDist to ship:AIRSPEED^2 / (2 * maxDecel).  // The distance the burn will require
lock idealThrottle to stopDist / trueRadar. // Throttle required for perfect hoverslam
lock impactTime to trueRadar / abs(ship:verticalspeed). // Time until impact
lock startTime to ((trueRadar - stopDist) / abs(ship:verticalspeed)) - 4. // Time until impact  (3 is for engine startup time)
Set AltOffset to 100. //Target location altitude offset

//Flight Conditions Init
set RShut to 0. //Enables main guidance loop
set landingStart to 0.  //Enables Landing Legs deploy
Set gain to -1. //proportion for landing burn
Set ovrshootGain to 2. //Gain to adjust rate that overshoot amount closes to target relative to vehicle distance
ag6 off.  //shutdown outer engine ring

//Fuel Transfer
print "Transfering Fuel".
SET T1 to SHIP:PARTSDUBBED("1").  //bottom tank
SET T2 to SHIP:PARTSDUBBED("2").  //2nd from bottom tank
SET T3 to SHIP:PARTSDUBBED("3").  //3rd from bottom tank
SET T4 to SHIP:PARTSDUBBED("4").  //3rd from top tank
SET T5 to SHIP:PARTSDUBBED("5").  //2nd from top tank
SET T6 to SHIP:PARTSDUBBED("6").  //top tank
SET T7 to SHIP:PARTSDUBBED("7").  //extra tank
SET T8 to SHIP:PARTSDUBBED("7").  //extra tank 2
print "Fuel Transfer Start".
wait .1.
SET LF8 TO TRANSFERALL("LqdMethane", T8, T1).
SET LF7 TO TRANSFERALL("LqdMethane", T7, T1).
SET LF6 TO TRANSFERALL("LqdMethane", T6, T1).
SET LF5 TO TRANSFERALL("LqdMethane", T5, T1).
SET LF4 TO TRANSFERALL("LqdMethane", T4, T1).
SET LF3 TO TRANSFERALL("LqdMethane", T3, T1).
SET LF2 TO TRANSFERALL("LqdMethane", T2, T1).
wait .1.
print "Liguid Fuel Transfer Nominal".
SET LF8:ACTIVE to TRUE.
SET LF7:ACTIVE to TRUE.
SET LF6:ACTIVE to TRUE.
SET LF5:ACTIVE to TRUE.
SET LF4:ACTIVE to TRUE.
SET LF3:ACTIVE to TRUE.
SET LF2:ACTIVE to TRUE.
print "Liguid Fuel Transfer Complete".
wait .1.
SET OX8 TO TRANSFERALL("OXIDIZER", T8, T1).
SET OX7 TO TRANSFERALL("OXIDIZER", T7, T1).
SET OX6 TO TRANSFERALL("OXIDIZER", T6, T1).
SET OX5 TO TRANSFERALL("OXIDIZER", T5, T1).
SET OX4 TO TRANSFERALL("OXIDIZER", T4, T1).
SET OX3 TO TRANSFERALL("OXIDIZER", T3, T1).
SET OX2 TO TRANSFERALL("OXIDIZER", T2, T1).
print "Oxidizer Fuel Transfer Nominal".
wait .1.
SET OX8:ACTIVE to TRUE.
SET OX7:ACTIVE to TRUE.
SET OX6:ACTIVE to TRUE.
SET OX5:ACTIVE to TRUE.
SET OX4:ACTIVE to TRUE.
SET OX3:ACTIVE to TRUE.
SET OX2:ACTIVE to TRUE.
print "Oxidizer Fuel Transfer Complete".
    
print "Guidance V3.2".
SET Vehicle_Status to "Status [ 1 ]".
rcs off.
unlock steering.
sas on.
WAIT UNTIL ship:verticalspeed < -10.  //wait until decent

SET Vehicle_Status to "Status [ 2 ]".
print "Vehicle Status" at(0,20).
print Vehicle_Status at(20,20).
wait .1.
//Steering Logic
lock ShipPos to SHIP:GEOPOSITION.  //gets lat lng coordinates of the target
set targetGeo to LATLNG(28.6068,-80.5983).  //adds lng adjustment to coordinates
lock targetPos to targetGeo:POSITION. //gets vector to coordinates
lock errorVector to addons:tr:impactpos:position - targetGeo:position.  //difference between predicted landing and wanted landing
lock velVector to -ship:velocity:surface. //Literally what it says
lock result to velVector + errorVector. //Adds velocity and error to get adjustment vector
lock steer to lookdirup(result, facing:upvector).  //flies result vector with relationship to up
lock lngoff to (targetGeo:lng - addons:tr:impactpos:lng). //difference between wanted and predicted landing
lock boostbackv to (addons:tr:impactpos:position - targetGeo:position). //horizontal adjust angle for entry burn
lock line_of_sight to targetGeo:ALTITUDEPOSITION(AltOffset).  //Vector to target location with altitude offset
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
sas off.
Lights on.
set throt to 0.
LOCK THROTTLE TO throt. //initiate throttle control
lock steering to lookdirup(-VELOCITY:SURFACE, facing:upvector). //steer to velocity vector -> AKA flamy end down
wait 2.
rcs on.

UNTIL RShut = 1 { //Main Flight Control Loop
  print "Velocity" at(0,21).
  print ship:groundspeed at(20,21).
  print "Vehicle Status" at(0,20).
  print Vehicle_Status at(20,20).
  print "lngoff" at(0, 22).
  print lngoff at(20, 22).
  print "Time to Landing burn" at(0, 24).
  print startTime at(20, 24).

  if ALT:RADAR < 3000 AND startTime < 0 { //Landing Burn
    set limit to 50. //full aero control
    SHIP:PARTSDUBBED("fin")[0]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
    SHIP:PARTSDUBBED("fin")[1]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
    SHIP:PARTSDUBBED("fin")[2]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
    SHIP:PARTSDUBBED("fin")[3]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).

    until ship:verticalspeed > -0.1 { //Actually doing guidance here
      if trueRadar > 300 {
        print "Velocity" at(0,21).
        print ship:groundspeed at(20,21).
        print "Vehicle Status" at(0,20).
        print Vehicle_Status at(20,20).
        print "lngoff" at(0, 22).
        print lngoff at(20, 22).
        print "gain" at(0, 23).
        print gain at(20, 23).
        print "Time to Landing burn" at(0, 24).
        print startTime at(20, 24).

        if trueRadar < 900 AND landingStart = 0 {  //Deploy landing legs and target
          Set gain to -1. //Control gain
          Set AltOffset to 0. //Target location altitude offset
          set radarOffset to 0.  //Onboard altimeter adjustment (CoM to ground)
          set landingStart to 1.  //Locks out statement
          unlock steering. //reset steering
        }
        Set gain to -2. //More control gain
        rcs off.
        SET Vehicle_Status to "Status [ 7 ]".
        //Control Angle Calc thing
        set output to -1*ship:velocity:surface*angleAxis(1*gain*vang(line_of_sight,ship:velocity:surface),vcrs(ship:velocity:surface,line_of_sight)).
        //EXPLANATION: Takes the angle between target vector and velocity vector. Then takes cross product between the two to give a correction amount in the correct direction. This is than multiplied by a gain to increase control amount and veloctiy vector to give the vector a magnitude.
        //SET vdoutputVector TO VECDRAW(v(0,0,0),output,RGB(1,0,0),"Control",1,TRUE,0.5,TRUE).  //Draws Guidance Vector
        //SET vdoutputVector TO VECDRAW(v(0,0,0),line_of_sight,RGB(0,1,0),"LOS",1,TRUE,0.5,TRUE).  //Draws Target Vector
        //SET vdoutputVector TO VECDRAW(v(0,0,0),ship:velocity:surface,RGB(0,0,1),"Vel",1,TRUE,0.5,TRUE).  //Draws Velocity Vector
        lock steering to lookdirup(output, facing:upvector). //output vector with specified rotation
        lock throttle to idealThrottle. //Initiate landing burn to continuously adjust for good landing
      }
      else {
        until ship:verticalspeed > -0.1 { //kill all horz and vert velocity in last 150 meters for soft landing...hopefully
          print "Velocity" at(0,21).
          print ship:groundspeed at(20,21).
          print "Vehicle Status" at(0,20).
          print Vehicle_Status at(20,20).
          SET Vehicle_Status to "Status [ 8 ]".
          set radarOffset to 27.  //Onboard altimeter adjustment (CoM to ground)
          set limit to 51. //full aero control
          rcs on.
          SHIP:PARTSDUBBED("fin")[0]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
          SHIP:PARTSDUBBED("fin")[1]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
          SHIP:PARTSDUBBED("fin")[2]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
          SHIP:PARTSDUBBED("fin")[3]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
          if trueRadar < 200 {
            gear on.
          }
          lock steering to srfretrograde.
          lock throttle to idealThrottle. 
        }
      }
    }
    Set RShut to 1. //stop guidance
    LOCK THROTTLE TO 0.
    unlock all. //prevent errors caused by landing
  }
  else {
    //Entry Burn
    if ALT:RADAR < 50000 AND EntryBurn = 0 {
      until ship:AIRSPEED < 950 {
       lock steering to lookdirup(-VELOCITY:SURFACE, facing:upvector).
        SET Vehicle_Status to "Status [ 4 ]".
        AG6 off.
        AG5 on.
        AG4 on.
        if ALT:RADAR < 45000 {  //starts entry burn
          rcs off.
          set throt to .7.
        }
      }
      set EntryBurn to 1.
      rcs on.
    }
    else {
      AG6 off.
      AG5 off.
      AG4 on.
      if ALT:RADAR > 50000 {
        rcs on.
        SET Vehicle_Status to "Status [ 3 ]".
        LOCK STEERING TO lookdirup(-VELOCITY:SURFACE, facing:upvector). //steer to velocity vector -> AKA flamy end down
      }
      else {
        SET Vehicle_Status to "Status [ 6 ]".
        LOCK STEERING TO steer. //Control along aerodynamic guidance vector
        set limit to 20. //full aero control
        SHIP:PARTSDUBBED("fin")[0]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
        SHIP:PARTSDUBBED("fin")[1]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
        SHIP:PARTSDUBBED("fin")[2]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
        SHIP:PARTSDUBBED("fin")[3]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
        rcs off.
      }
      SET throt TO 0.
    }
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