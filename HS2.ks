//FOR USE WITH ARCMax
//HS2 = Booster Flight Script
CLEARSCREEN.
set INCLINATION to 90. //set Orbital inclination
print "STATUS:" at (0,9).
print "[Nominal]" at(0,10).
wait until SHIP:APOAPSIS > 71000.
wait 7.
print "Coasting".
sas off.
lock steering to prograde.
rcs on.
wait 1.
wait until ALT:RADAR > 55000.
//guidance init
rcs on.
sas off.
wait .7.
lock throttle to 0.
SET pitchUp to HEADING(INCLINATION,180).
set approachAngle to pitchUp.
wait 0.01.

//set approachAngle to heading(inclination,180).
print "REORIENTATION".
lock steering to approachAngle.
print approachAngle at(0,2).
wait 10.
sas off.
wait 2.
toggle AG4.
lock throttle to 1.
print "STATUS:" at (0,9).
print "Boostback [BRAKING]" at(0, 10).
until SHIP:GROUNDSPEED < 10 {
  print SHIP:GROUNDSPEED at(0,11).
}

//Boostback
CLEARSCREEN.
print "STATUS:" at (0,9).
print "Boostback [ACCELERATING]" at(0, 10).
until SHIP:GROUNDSPEED > 47 {                   // BOOSTBACK
  print "Ground Velocity:" at(0,14).
  print SHIP:GROUNDSPEED at(0,15).
  wait 0.
}.
lock throttle to 0.
CLEARSCREEN.
print "Landing Guidance [NOMINAL]".
set targetGeo to LATLNG(25.9966,-97.1067).
lock targetPos to targetGeo:POSITION.
print targetPos.
wait 1.
LOCK STEERING TO -targetPos. //this is lat long of target
Lights off.
wait 1.
Lights on.
print "Landing Guidance".
rcs on.
AG7 on.
print "Brake Deployed [NOMINAL]".

WAIT UNTIL ship:verticalspeed < -10.
rcs off.
unlock steering.
sas off.
WAIT UNTIL ALT:RADAR < 68000.
rcs on.

//Vector Guidance Init
LOCAL surfGrav IS BODY:MU / BODY:RADIUS^2.  //surface gravity for current body
LOCAL throt IS 0.
LOCK THROTTLE TO throt.
set vecTar to SHIP:FACING:VECTOR.  //initializing the target vector with the current facing vector of the ship
wait .1.
LOCK steering TO vecTar.
sas off.
sas on.
set accelAdjust to 15.0.
wait .5.
sas off.

print "Transfering Fuel".
SET header to SHIP:PARTSDUBBED("Header").
SET central to SHIP:PARTSDUBBED("Central").
SET base to SHIP:PARTSDUBBED("Base").
print "Fuel Transfer Start".
wait .1.
SET LF1 TO TRANSFERALL("LqdMethane", header, central).
SET LF2 TO TRANSFERALL("LqdMethane", central, base).
wait .1.
print "Liguid Fuel Transfer Nominal".
SET LF1:ACTIVE to TRUE.
SET LF2:ACTIVE to TRUE.
print "Liguid Fuel Transfer Complete".
wait .1.
SET OX1 TO TRANSFERALL("OXIDIZER", header, central).
SET OX2 TO TRANSFERALL("OXIDIZER", central, base).
print "Oxidizer Fuel Transfer Nominal".
wait .1.
SET OX1:ACTIVE to TRUE.
SET OX2:ACTIVE to TRUE.
print "Oxidizer Fuel Transfer Complete".

//Vector Guidance
UNTIL ALT:RADAR < 1000 {
    LOCAL faceVec IS SHIP:FACING:VECTOR.    //Current Direction
    
    LOCAL VelocityVector IS SHIP:VELOCITY:SURFACE.  //Velocity Vector
    SET vdVelocityVector TO VECDRAW(v(0,0,0),VelocityVector,RGB(1,1,0),"Velocity Vector",1,TRUE,0.1,TRUE).
    
    LOCAL TargetVector IS targetPos.        //Target Vector
    SET vdTargetVector TO VECDRAW(v(0,0,0),TargetVector,RGB(1,0,0),"Target Vector",1,TRUE,0.1,TRUE).
    
    LOCAL accel IS (SHIP:AVAILABLETHRUST / SHIP:MASS - surfGrav) * accelAdjust. //Available acceleration minus gravity.
    LOCAL wantVelocityVector IS TargetVector:NORMALIZED * SQRT(2 * TargetVector:MAG * accel). //Converting the distance to desired velocity using kinematic equation
    //NOTE:
      //Normalizing a vector keeps it's direction but sets the length (magnitude) to 1
      //Multiplying a vector by a number multiples it's magnitude by that number
    SET vdWantVelocityVector TO VECDRAW(v(0,0,0),wantVelocityVector,RGB(0,1,0),"Wanted Velocity Vector",1,TRUE,0.2,TRUE).
    
    LOCAL ErrorVector IS wantVelocityVector - VelocityVector. //Difference between the wanted velocity and the current velocity
    SET vdErrorVector TO VECDRAW(VelocityVector,ErrorVector,RGB(0,0,1),"Error Vector",1,TRUE,0.1,TRUE).
    
    IF VDOT(ErrorVector,VelocityVector) < 0 { // a vector dot product (VDOT) is some what complicated
        SET vecTar TO ErrorVector.    // (usually -) but in this if the result is negative then the 2 vectors are more than 90 degrees away from each other
        print "Positive Error" at(0,19).
        set throt to 1.
        print "Speed Adjust" at(0,20).
        wait 0.
    } 
    ELSE {                       // which means that the desired velocity is less than the current velocity and as such can be used for steering input
        SET vecTar TO -ErrorVector.   
        print "Negative Error" at(0,19). // if the result is still positive then the desired velocity is larger than the current velocity so we will use the inverse for steering
        wait 0.
    }

    //Flight Events
    //Entry Burn
    if ALT:RADAR < 20000 AND SHIP:AIRSPEED > 450 {
      AG4 off.
      set throt to 1.
      lock steering to ErrorVector.
      set accelAdjust to .18.
      wait 0.
    }
    else if ALT:RADAR < 20000 AND SHIP:AIRSPEED > 315 AND SHIP:AIRSPEED < 450 AND ALT:RADAR > 12000 {
      set throt to 1.
      AG4 on.
      lock steering to ErrorVector.
      set accelAdjust to .7.
      wait 0.
    }
    else if ALT:RADAR < 20000 AND SHIP:AIRSPEED > 280 AND SHIP:AIRSPEED < 315 AND ALT:RADAR > 8500 {
      set throt to .8.
      AG4 on.
      set accelAdjust to 11.
      lock steering to vecTar.
      wait 0.
    }
    else if ALT:RADAR < 2000 {
      lock throttle to 0.2.
      set accelAdjust to 5.
      print "Startup [NOMINAL]" at(0,32).
      lock steering to vecTar.
      wait 0.
    }
    else {
        IF VDOT(ErrorVector,VelocityVector) > 0 {
            SET throt TO 0. 
            print "Speed Nominal" at(0,20).
            wait 0.
            if ALT:RADAR > 7500 AND ALT:RADAR < 8000 {
              set accelAdjust to 8.
              lock steering to vecTar.
              wait 0.
            }
            else if ALT:RADAR > 5500 AND ALT:RADAR < 6000 {
                set accelAdjust to 5.
                lock steering to vecTar.
                wait 0.
            }
        }
        LOCK STEERING TO vecTar.
        wait 0.
    }
    print "Velocity Data" at(0,24).
    print VDOT(ErrorVector,VelocityVector) at(0,25).
                                        // in this case because the results of SHIP:FACING:VECTOR will always be have a magnitude of 1
                                        // the result of the VDOT will be how long the ErrorVector is along the faceVec axis
                                        // think of it as like measuring the vertical height of a tilted thing
                                        // but where the vector with a magnitude of 1 defines the "up" direction
                                        // The division by accel is because that represents what the throttle can do given an error
    WAIT 0.
}
set limit to 10.
SHIP:PARTSDUBBED("fin")[0]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
SHIP:PARTSDUBBED("fin")[1]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
SHIP:PARTSDUBBED("fin")[2]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
SHIP:PARTSDUBBED("fin")[3]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
sas off.
wait .1.
print "Landing Burn Startup".
wait .1.
lock steering to srfretrograde.
print "Approaching" AT(0,32).
toggle AG4.

CLEARSCREEN.
set radarOffset to 17.	 				// The value of alt:radar when landed (on gear)
lock trueRadar to alt:radar - radarOffset.			// Offset radar to get distance from gear to ground
lock g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)
lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
lock stopDist to ship:verticalspeed^2 / (2 * maxDecel).		// The distance the burn will require
lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact, used for landing gear

WAIT UNTIL ship:verticalspeed < -1.
	print "Landing Burn F1 [Nominal]".
	rcs on.
	sas off.
  gear on.
  lock throttle to .2.
	lock steering to srfretrograde.

WAIT UNTIL trueRadar < stopDist.
	print "Landing Burn F2 [Nominal]".
	lock throttle to idealThrottle.

WAIT UNTIL ship:verticalspeed > -0.01.
	print "Landing Burn [Nominal]".
	set ship:control:pilotmainthrottle to 0.
	rcs off.

lock steering to up.
PRINT "ENGINE SHUTDOWN".
LOCK THROTTLE TO 0.
rcs on.
WAIT 1.
sas off.
UNLOCK STEERING.
AG7 off.
sas off.
wait 1.
rcs off.
lock throttle to 0.
lights off.
unlock throttle.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
print "Handing Rocket Control over to Manual Control".
wait .1.
print "Vehicle Ready for Recovery".
print "---------------------------------------".
print "ARC S2 Will now Exit".
SHUTDOWN.