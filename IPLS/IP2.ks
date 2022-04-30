//FOR USE WITH IPLS
//HS2 = Booster Flight Script
CLEARSCREEN.
set INCLINATION to 90. //set Orbital inclination
set boostback to 0.     //0 = water    1 = land
set driftAdjust to 0.000. //droneship adjustment

print "STATUS:" at (0,9).
print "[Nominal]" at(0,10).
wait until ALT:RADAR > 1000.
if boostback = 0 {
  set target to "DroneShip".
  wait 1.
  set DronePos to Target:GEOPOSITION.
  set targetGeo TO DronePos.
}
wait until SHIP:APOAPSIS > 70000.
wait 3.
print "Coasting".
sas off.
lock steering to up.
rcs on.
wait 1.
print "Transfering Fuel".
SET header to SHIP:PARTSDUBBED("Header").
SET central to SHIP:PARTSDUBBED("Central").
SET base to SHIP:PARTSDUBBED("Base").
print "Fuel Transfer Start".
wait .1.
SET LF1 TO TRANSFERALL("LqdMethane", header, central).
SET LF2 TO TRANSFERALL("LqdMethane", base, central).
wait .1.
print "Liguid Fuel Transfer Nominal".
SET LF1:ACTIVE to TRUE.
SET LF2:ACTIVE to TRUE.
print "Liguid Fuel Transfer Complete".
wait .1.
SET OX1 TO TRANSFERALL("OXIDIZER", header, central).
SET OX2 TO TRANSFERALL("OXIDIZER", base, central).
print "Oxidizer Fuel Transfer Nominal".
wait .1.
SET OX1:ACTIVE to TRUE.
SET OX2:ACTIVE to TRUE.
print "Oxidizer Fuel Transfer Complete".
wait until ALT:RADAR > 35000.
//guidance init
if boostback = 1 {
  set targetGeo to LATLNG(25.9807,-97.0812).  //land
}
print targetGeo.
rcs on.
sas off.
wait .5.
lock throttle to 0.
wait 0.01.
set SteeringManager:MAXSTOPPINGTIME to 2.5.
set STEERINGMANAGER:PITCHTS to 1.
set STEERINGMANAGER:YAWTS to 1.

if boostback = 1 {
  print "REORIENTATION".

  lock lngoff to (targetGeo:lng - addons:tr:impactpos:lng).
  lock latoff to (targetGeo:lat - addons:tr:impactpos:lat).
  lock boostbackv to (addons:tr:impactpos:position - targetGeo:position).
  set horzBoost to vxcl(up:forevector, boostbackv).
  lock steering to -boostbackv.

  sas on.
  wait 1.
  sas off.
  wait 14.
  AG4 off.

  lock throttle to 1.
  wait until lngoff >= 0.
  lock throttle to 0.
}
if boostback = 0 {
  print "REORIENTATION".

  lock lngoff to (targetGeo:lng - addons:tr:impactpos:lng).
  lock latoff to (targetGeo:lat - addons:tr:impactpos:lat).
  lock boostbackv to (addons:tr:impactpos:position - targetGeo:position).
  set horzBoost to vxcl(up:forevector, boostbackv).
  lock steering to -boostbackv.

  wait 20.
  AG4 off.

  lock throttle to .1.
  wait until lngoff >= 0.
  lock throttle to 0.
}
rcs off.

CLEARSCREEN.
print "Landing Guidance [NOMINAL]".
lock targetPos to targetGeo:POSITION.
print targetPos.
wait 1.
LOCK STEERING TO -targetPos.
Lights off.
wait 1.
Lights on.
print "Landing Guidance".
AG7 on.
print "Brake Deployed [NOMINAL]".
WAIT UNTIL ship:verticalspeed < -100.
LOCK STEERING TO -targetPos.
sas off.
WAIT UNTIL ALT:RADAR < 60000.

//Vector Guidance Init
LOCAL surfGrav IS BODY:MU / BODY:RADIUS^2.  //surface gravity for current body
LOCAL throt IS 0.
LOCK THROTTLE TO throt.
set vecTar to SHIP:FACING:VECTOR.  //initializing the target vector with the current facing vector of the ship
wait .1.
LOCK steering TO vecTar.
sas off.
sas on.
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
rcs on.

lock targetPos to targetGeo:POSITION.

set accelAdjust to 5.
set VectorLevel to 100000.
set stopBurn to 0.
set landingStart to 1.
set landingStart2 to 1.
set Landingadjust to .9.
set targetLoad to 1.

if boostback = 0 {
  set radarOffset to 150.	
}
else {
  set radarOffset to 29.	 				// The value of alt:radar when landed (on gear)         26 for land 
}
lock trueRadar to alt:radar - radarOffset.			// Offset radar to get distance from gear to ground
lock g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)
lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
lock stopDist to ship:verticalspeed^2 / (2 * maxDecel).		// The distance the burn will require
lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact, used for landing gear

//Vector Guidance
UNTIL ship:verticalspeed > -0.01 { 
    SET faceVec TO SHIP:FACING:VECTOR.    //Current Direction
    
    SET VelocityVector TO SHIP:VELOCITY:SURFACE.  //Velocity Vector
    //SET vdVelocityVector TO VECDRAW(v(0,0,0),VelocityVector,RGB(1,1,0),"Velocity Vector",1,TRUE,0.1,TRUE).
    
    SET TargetVector TO targetPos.        //Target Vector
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

    //Flight Events
    //Entry Burn
    //landingzone
    if boostback = 1 AND ALT:RADAR > 1000 {
      if ALT:RADAR < 19000 AND SHIP:AIRSPEED > 390 AND entryBurn = 0 {
        print "Vehicle Status [EB1]" at(0,30).
        rcs off.
        AG4 on.
        set limit to 5.
        SHIP:PARTSDUBBED("fin")[0]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
        SHIP:PARTSDUBBED("fin")[1]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
        SHIP:PARTSDUBBED("fin")[2]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
        SHIP:PARTSDUBBED("fin")[3]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
        set throt to 1.
        lock steering to ErrorVector.
        set VectorLevel to -200000.
        print "Speed Adjust     " at(0,20).
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
      else if ALT:RADAR < 19000 AND SHIP:AIRSPEED > 310 AND SHIP:AIRSPEED < 390 AND ALT:RADAR > 10000 AND entryBurn = 0 {
        print "Vehicle Status [EB2]             " at(0,30).
        rcs off.
        set throt to 1.
        AG4 off.
        lock steering to ErrorVector.
        set VectorLevel to -20000.
        print "Speed Adjust       " at(0,20).
        if VDOT(ErrorVector,VelocityVector) > VectorLevel {
          set accelAdjust to abs(accelAdjust - .01).
        }
        else if VDOT(ErrorVector,VelocityVector) < VectorLevel {
          set accelAdjust to abs(accelAdjust + .01).
        }
        if accelAdjust > .5 {
          set accelAdjust to .5.
        }
        else if accelAdjust < .01 {
          set accelAdjust to .01.
        }
        print "Accel Adjust" at(0,27).
        print accelAdjust at(0,28).
      }
      else if ALT:RADAR < 19000 AND SHIP:AIRSPEED > 280 AND SHIP:AIRSPEED < 310 AND ALT:RADAR > 14000 {
        print "Vehicle Status [EB3]             " at(0,30).
        rcs off.
        set entryBurn to 1.
        set limit to 50.
        SHIP:PARTSDUBBED("fin")[0]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
        SHIP:PARTSDUBBED("fin")[1]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
        SHIP:PARTSDUBBED("fin")[2]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
        SHIP:PARTSDUBBED("fin")[3]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
        set throt to .6.
        AG4 off.
        lock steering to vecTar.
        set VectorLevel to 5000.
        print "Speed Adjust         " at(0,20).
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
      }
      else {
      print "Vehicle Status [NOMINAL]" at(0,30).
      rcs on.
      if VDOT(ErrorVector,VelocityVector) > 0 {
      SET throt TO 0. 
      print "Speed Nominal" at(0,20).
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
      }
        LOCK STEERING TO vecTar.
      }
    }
    else if boostback = 1 AND ALT:RADAR < 1000 {
      CLEARSCREEN.
      set radarOffset to 29.	 				// The value of alt:radar when landed (on gear)         26 for land
      lock trueRadar to alt:radar - radarOffset.			// Offset radar to get distance from gear to ground
      set g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)
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
    }

    //droneship Entry
    else if ALT:RADAR > 5000 AND boostback = 0 {
        if targetLoad = 1 {
          set target to "DroneShip".
          wait .01.
        }
        set DronePos to Target:GEOPOSITION.
        set targetGeo TO LATLNG((DronePos:LAT + driftAdjust),DronePos:LNG).
        set targetLoad to 0.
        if ALT:RADAR < 18000 AND SHIP:AIRSPEED > 700 {
          print "Vehicle Status [EB1]" at(0,30).
          lock steering to up.
          rcs off.
          AG4 on.
          set limit to 40.
          SHIP:PARTSDUBBED("fin")[0]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
          SHIP:PARTSDUBBED("fin")[1]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
          SHIP:PARTSDUBBED("fin")[2]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
          SHIP:PARTSDUBBED("fin")[3]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
          set throt to 1.
        }
        else {
          AG4 on.
          print "Vehicle Status [NOMINAL]" at(0,30).
          set VectorLevel to 200000.
          if VDOT(ErrorVector,VelocityVector) > 0 {
          SET throt TO 0.
          print "Speed Nominal" at(0,20).
          if VDOT(ErrorVector,VelocityVector) > VectorLevel {
            set accelAdjust to abs(accelAdjust - .01).
          }
          else if VDOT(ErrorVector,VelocityVector) < VectorLevel {
            set accelAdjust to abs(accelAdjust + .01).
          }
          if accelAdjust > 10 {
            set accelAdjust to 10.
          }
          else if accelAdjust < .01 {
            set accelAdjust to .01.
          }
          print "Accel Adjust" at(0,27).
          print accelAdjust at(0,28).
          }
          if SHIP:AIRSPEED < 700 AND ALT:RADAR < 18000 {
            LOCK STEERING TO vecTar.
          }
          else {
            LOCK STEERING TO srfretrograde.
          }
        }
    }
    //droneship landing translate
    else if trueRadar < (stopDist + 200) AND ALT:RADAR < 5000 AND ALT:RADAR > 50 AND boostback = 0 {
        print "Landing Burn F2 [Nominal]" AT(0,30).
        if landingStart = 1 {
          set limit to 50.
          SHIP:PARTSDUBBED("fin")[0]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
          SHIP:PARTSDUBBED("fin")[1]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
          SHIP:PARTSDUBBED("fin")[2]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
          SHIP:PARTSDUBBED("fin")[3]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
          Set gain to -3.
          rcs on.
          sas off.
          wait .1.
        }
        Set line_of_sight to target:position - ship:position.
        set output to -1*ship:velocity:surface*angleAxis(gain*vang(line_of_sight,ship:velocity:surface),vcrs(ship:velocity:surface,line_of_sight)).
        lock throttle to idealThrottle.
        set landingStart to 0.
        lock steering to output.
        if ALT:RADAR < 200 {
            if landingStart2 = 1 {
                Set gain to -1.
                gear on.
                AG4 off.
                set radarOffset to 29.
            }
            set landingStart2 to 0.
        }
    }
    else if boostback = 0 AND ALT:RADAR < 50 {
        set limit to 50.
        SHIP:PARTSDUBBED("fin")[0]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
        SHIP:PARTSDUBBED("fin")[1]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
        SHIP:PARTSDUBBED("fin")[2]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
        SHIP:PARTSDUBBED("fin")[3]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
        lock steering to srfretrograde.
        lock throttle to idealThrottle.
    }
    else {
        if SHIP:AIRSPEED < 500 AND ALT:RADAR < 10000 {
          set VectorLevel to 50000.
        }
        else if SHIP:AIRSPEED < 425 AND ALT:RADAR < 10000 {
          set VectorLevel to 1000.
        }
        print "Vehicle Status [NOMINAL]" at(0,30).
        if VDOT(ErrorVector,VelocityVector) > 0 {
        SET throt TO 0. 
        print "Speed Nominal" at(0,20).
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
        }
    }
    print "Velocity Data" at(0,24).
    print SHIP:AIRSPEED at(0,31).
    print VDOT(ErrorVector,VelocityVector) at(0,25).
    WAIT 0.
}

//landing shutdown
set limit to 5.
SHIP:PARTSDUBBED("fin")[0]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
SHIP:PARTSDUBBED("fin")[1]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
SHIP:PARTSDUBBED("fin")[2]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
SHIP:PARTSDUBBED("fin")[3]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
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