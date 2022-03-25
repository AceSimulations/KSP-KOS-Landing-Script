//Vehicle Secondary Computer 2 (Use on stage 1/boosters)
//RTLS 

CLEARSCREEN.

//Flight Param
set INCLINATION to 90. //set Orbital inclination

//Init
set targetGeo to LATLNG(28.6068,-80.5983).  //land
lock targetPos to targetGeo:POSITION.
set accelAdjust to 5.
set VectorLevel to 1000000.
SET WARPMODE TO "PHYSICS".
set radarOffset to 36.	 				// The value of alt:radar when landed (on gear)         26 for land 
lock trueRadar to alt:radar - radarOffset.			// Offset radar to get distance from gear to ground
lock g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)
lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
lock stopDist to ship:verticalspeed^2 / (2 * maxDecel).		// The distance the burn will require
lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact
SET Vehicle_Status to "Status [ 1 ]".  //1=ascent 2=MECO/Stage Sep 3=Boostback 4=Entry 5=Approach 6=Landing Burn 7=Shutdown H=High Approach L=Low Approach 1EX=Entry Burn Part X
print "Vehicle Status" at(0,22).
print Vehicle_Status at(0,23).

WAIT UNTIL ALT:RADAR < 100000.

lock lngoff to (targetGeo:lng - addons:tr:impactpos:lng).
lock latoff to (targetGeo:lat - addons:tr:impactpos:lat).
lock boostbackv to (addons:tr:impactpos:position - targetGeo:position).
lock targetPos to targetGeo:POSITION.
LOCK STEERING TO -targetPos.

sas off.
SET Vehicle_Status to "Status [ 5 ]".   //1=ascent 2=MECO/Stage Sep 3=Boostback 4=Entry 5=Approach 6=Landing Burn 7=Shutdown H=High Approach L=Low Approach 1EX=Entry Burn Part X
print "Vehicle Status" at(0,22).
print Vehicle_Status at(0,23).
WAIT UNTIL ALT:RADAR < 80000.
SET WARP TO 0.
LOCAL surfGrav IS BODY:MU / BODY:RADIUS^2. 
AG7 on.
set throt to 0.
LOCK THROTTLE TO throt.
set vecTar to SHIP:FACING:VECTOR.
wait .1.
LOCK steering TO vecTar.
sas off.
sas on.
wait .5.
sas off.

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
rcs on.

UNTIL ship:verticalspeed > -0.01 { 
    SET faceVec TO SHIP:FACING:VECTOR.
    
    SET VelocityVector TO SHIP:VELOCITY:SURFACE.
    //SET vdVelocityVector TO VECDRAW(v(0,0,0),VelocityVector,RGB(1,1,0),"Velocity Vector",1,TRUE,0.1,TRUE).
    
    SET TargetVector TO targetPos.
    //SET vdTargetVector TO VECDRAW(v(0,0,0),TargetVector,RGB(1,0,0),"Target Vector",1,TRUE,0.1,TRUE).
    
    SET accel TO (SHIP:AVAILABLETHRUST / SHIP:MASS - surfGrav) * (accelAdjust + .0001).
    SET wantVelocityVector TO TargetVector:NORMALIZED * SQRT(2 * TargetVector:MAG * accel).
    //SET vdWantVelocityVector TO VECDRAW(v(0,0,0),wantVelocityVector,RGB(0,1,0),"Wanted Velocity Vector",1,TRUE,0.2,TRUE).
    
    SET ErrorVector TO wantVelocityVector - VelocityVector.
    //SET vdErrorVector TO VECDRAW(VelocityVector,ErrorVector,RGB(0,0,1),"Error Vector",1,TRUE,0.1,TRUE).
    
    IF VDOT(ErrorVector,VelocityVector) < 0 {
        SET vecTar TO ErrorVector. 
        print "Positive Error" at(0,19).
    } 
    ELSE {
        SET vecTar TO -ErrorVector.   
        print "Negative Error" at(0,19).
    }

    //RTLS
    if ALT:RADAR > 2000 {
      if ALT:RADAR < 25000 AND SHIP:AIRSPEED > 950 {
         SET Vehicle_Status to "Status [1E1]".   //1=ascent 2=MECO/Stage Sep 3=Boostback 4=Entry 5=Approach 6=Landing Burn 7=Shutdown H=High Approach L=Low Approach 1EX=Entry Burn Part X
          rcs off.
          AG4 on.
          set limit to 5.
          SHIP:PARTSDUBBED("fin")[0]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
          SHIP:PARTSDUBBED("fin")[1]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
          SHIP:PARTSDUBBED("fin")[2]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
          SHIP:PARTSDUBBED("fin")[3]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
          set throt to 1.
          lock steering to ErrorVector.
          set VectorLevel to -150000.
          if VDOT(ErrorVector,VelocityVector) > VectorLevel {
            set accelAdjust to abs(accelAdjust - .01).
          }
          else if VDOT(ErrorVector,VelocityVector) < VectorLevel {
              set accelAdjust to abs(accelAdjust + .01).
          }
          if accelAdjust > .3 {
              set accelAdjust to .3.
          }
          else if accelAdjust < .01 {
            set accelAdjust to .01.
          }
          print "Accel Adjust" at(0,27).
          print accelAdjust at(0,28).
      }
      else if ALT:RADAR < 25000 AND SHIP:AIRSPEED < 950 AND SHIP:AIRSPEED > 900 {
          SET Vehicle_Status to "Status [1E2]".  //1=ascent 2=MECO/Stage Sep 3=Boostback 4=Entry 5=Approach 6=Landing Burn 7=Shutdown H=High Approach L=Low Approach 1EX=Entry Burn Part X
          set VectorLevel to 5000.
          AG4 off.
          set throt to 1.
          set limit to 40.
          SHIP:PARTSDUBBED("fin")[0]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
          SHIP:PARTSDUBBED("fin")[1]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
          SHIP:PARTSDUBBED("fin")[2]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
          SHIP:PARTSDUBBED("fin")[3]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
      }
      else {
          AG4 off.
          SET Vehicle_Status to "Status [ 5 ]".  //1=ascent 2=MECO/Stage Sep 3=Boostback 4=Entry 5=Approach 6=Landing Burn 7=Shutdown H=High Approach L=Low Approach 1EX=Entry Burn Part X
          rcs on.
          if VDOT(ErrorVector,VelocityVector) > VectorLevel {
              set accelAdjust to abs(accelAdjust - .01).
          }
          else if VDOT(ErrorVector,VelocityVector) < VectorLevel {
            set accelAdjust to abs(accelAdjust + .01).
          }
          if accelAdjust > 8 {
            set accelAdjust to 8.
          }
          else if accelAdjust < .01 {
              set accelAdjust to .01.
          }
          print "Accel Adjust" at(0,27).
          print accelAdjust at(0,28).
          set throt to 0.
      }
      LOCK STEERING TO vecTar.
    }
    else if ALT:RADAR < 2000 AND trueRadar < stopDist {
      SET Vehicle_Status to "Status [6P0]".  //1=ascent 2=MECO/Stage Sep 3=Boostback 4=Entry 5=Approach 6=Landing Burn 7=Shutdown H=High Approach L=Low Approach 1EX=Entry Burn Part X
      set radarOffset to 36.	 				// The value of alt:radar when landed (on gear)         26 for land
      lock trueRadar to alt:radar - radarOffset.			// Offset radar to get distance from gear to ground
      set g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)
      lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
      lock stopDist to ship:verticalspeed^2 / (2 * maxDecel).		// The distance the burn will require
      lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
      lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact, used for landing gear

      WAIT UNTIL ship:verticalspeed < -1.
        rcs on.
        sas off.
        AG4 off.
        gear on.
        lock throttle to 0.
        SET Vehicle_Status to "Status [6P1]".  //1=ascent 2=MECO/Stage Sep 3=Boostback 4=Entry 5=Approach 6=Landing Burn 7=Shutdown H=High Approach L=Low Approach 1EX=Entry Burn Part X
        lock steering to srfretrograde.

      WAIT UNTIL trueRadar < stopDist.
        SET Vehicle_Status to "Status [6P2]".  //1=ascent 2=MECO/Stage Sep 3=Boostback 4=Entry 5=Approach 6=Landing Burn 7=Shutdown H=High Approach L=Low Approach 1EX=Entry Burn Part X
        lock throttle to idealThrottle.

      WAIT UNTIL ship:verticalspeed > -0.01.
        SET Vehicle_Status to "Status [ 7 ]".  //1=ascent 2=MECO/Stage Sep 3=Boostback 4=Entry 5=Approach 6=Landing Burn 7=Shutdown H=High Approach L=Low Approach 1EX=Entry Burn Part X
        set ship:control:pilotmainthrottle to 0.
        rcs off.
    }
    print "Velocity Data" at(0,24).
    print SHIP:AIRSPEED at(0,31).
    print VDOT(ErrorVector,VelocityVector) at(0,25).
    WAIT 0.
    print "Vehicle Status" at(0,22).
    print Vehicle_Status at(0,23).
}

SET Vehicle_Status to "Status [ 7 ]".  //1=ascent 2=MECO/Stage Sep 3=Boostback 4=Entry 5=Approach 6=Landing Burn 7=Shutdown H=High Approach L=Low Approach 1EX=Entry Burn Part X
set limit to 5.
SHIP:PARTSDUBBED("fin")[0]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
SHIP:PARTSDUBBED("fin")[1]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
SHIP:PARTSDUBBED("fin")[2]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
SHIP:PARTSDUBBED("fin")[3]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
set ship:control:pilotmainthrottle to 0.
rcs on.
lock steering to up.
LOCK THROTTLE TO 0.
rcs on.
WAIT 5.
sas off.
UNLOCK STEERING.
AG7 off.
sas off.
rcs off.
lights off.
unlock throttle.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
SHUTDOWN.