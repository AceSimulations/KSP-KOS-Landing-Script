//Vehicle Main Computer 2 (Use on stage 1/boosters)

CLEARSCREEN.

WAIT UNTIL ship:verticalspeed < -10.

//Flight Param
set INCLINATION to 90. //set Orbital inclination

//Init
set driftAdjust to 0.0025. //droneship LNG position adjustment
set accelAdjust to 2.
set VectorLevel to 500000.
set stopBurn to 0.
set landingStart to 1.
set landingStart1 to 1.
set landingStart2 to 1.
set Landingadjust to .9.
set RShut to 0.
set targetLoad to 1.
set LandingVelCheck to 0.
lock entryYawDir to lookdirup(vecTar, up:vector).
lock EntryAngle to Heading(srfretrograde:pitch, entryYawDir:yaw, srfretrograde:roll).
SET WARPMODE TO "PHYSICS".
set EntryBurn to 0.
set radarOffset to 0.
lock trueRadar to alt:radar - radarOffset.			// Offset radar to get distance from gear to ground
lock g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)
lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
lock stopDist to ship:AIRSPEED^2 / (2 * maxDecel).		// The distance the burn will require
lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact
SET Vehicle_Status to "Status [ 1 ]".  //1=ascent 2=MECO/Stage Sep 3=Boostback 4=Entry 5=Approach 6=Landing Burn 7=Shutdown H=High Approach L=Low Approach
print "Vehicle Status" at(0,22).
print Vehicle_Status at(0,23).
wait until ALT:RADAR > 1000.
set target to "DroneShip".
wait .1.
lock DronePos to Target:GEOPOSITION.
lock targetGeo TO LATLNG((DronePos:LAT),DronePos:LNG + driftAdjust).
lock targetPos to targetGeo:POSITION.
SET Vehicle_Status to "Status [ 2 ]".  //1=ascent 2=MECO/Stage Sep 3=Boostback 4=Entry 5=Approach 6=Landing Burn 7=Shutdown H=High Approach L=Low Approach
print "Vehicle Status" at(0,22).
print Vehicle_Status at(0,23).
sas off.
rcs off.
WAIT UNTIL ALT:RADAR < 90000.

AG7 on.
rcs on.
sas off.
lock steering to srfretrograde.

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

SET WARP TO 0.
sas off.
lock throttle to 0.
SET Vehicle_Status to "Status [ 3 ]".   //1=ascent 2=MECO/Stage Sep 3=Boostback 4=Entry 5=Approach 6=Landing Burn 7=Shutdown H=High Approach L=Low Approach
print "Vehicle Status" at(0,22).
print Vehicle_Status at(0,23).

lock lngoff to (targetGeo:lng - addons:tr:impactpos:lng).
lock latoff to (targetGeo:lat - addons:tr:impactpos:lat).
lock boostbackv to (addons:tr:impactpos:position - targetGeo:position).
lock horzBoost to vxcl(up:forevector, boostbackv).

rcs off.
lock targetPos to targetGeo:POSITION.
Lights on.
SET WARP TO 3.
WAIT UNTIL ship:verticalspeed < -100.
sas off.
SET Vehicle_Status to "Status [ 5 ]".   //1=ascent 2=MECO/Stage Sep 3=Boostback 4=Entry 5=Approach 6=Landing Burn 7=Shutdown H=High Approach L=Low Approach
print "Vehicle Status" at(0,22).
print Vehicle_Status at(0,23).
SET WARP TO 0.
LOCAL surfGrav IS BODY:MU / BODY:RADIUS^2. 
AG7 on.
set throt to 0.
LOCK THROTTLE TO throt.
set vecTar to SHIP:FACING:VECTOR.
wait .1.

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

UNTIL RShut = 1 { 
    //Aero Guidance Init
    lock faceVec TO SHIP:FACING:VECTOR.
    lock pretargetGeo to LATLNG(addons:tr:impactpos:lat,addons:tr:impactpos:lng).  //land
    lock pretargetPos to pretargetGeo:POSITION.
    lock VelocityVector TO pretargetPos:NORMALIZED * SHIP:VELOCITY:SURFACE:MAG.
    lock TargetVector TO targetPos.
    lock accel TO (SHIP:AVAILABLETHRUST / SHIP:MASS - surfGrav) * (accelAdjust).
    lock wantVelocityVector TO TargetVector:NORMALIZED * SQRT(2 * TargetVector:MAG * accel).
    lock ErrorVector TO wantVelocityVector - VelocityVector.

    lock errorVector to addons:tr:impactpos:position - targetGeo:position.
    lock velVector to -ship:velocity:surface.
    lock result to velVector + errorVector.
    lock steer to lookdirup(result, facing:topvector).

    // SET vdVelocityVector TO VECDRAW(v(0,0,0),VelocityVector,RGB(1,1,0),"Velocity Vector",1,TRUE,0.1,TRUE).
    // SET vdTargetVector TO VECDRAW(v(0,0,0),TargetVector,RGB(1,0,0),"Target Vector",1,TRUE,0.1,TRUE).
    // SET vdWantVelocityVector TO VECDRAW(v(0,0,0),wantVelocityVector,RGB(0,1,0),"Wanted Velocity Vector",1,TRUE,0.2,TRUE).
    // SET vdErrorVector TO VECDRAW(VelocityVector,ErrorVector,RGB(0,0,1),"Error Vector",1,TRUE,0.1,TRUE).
    
    IF VDOT(ErrorVector,VelocityVector) < 0 {
        SET vecTar TO ErrorVector. 
        print "Positive Error" at(0,19).
    } 
    ELSE {
        SET vecTar TO -ErrorVector.   
        print "Negative Error" at(0,19).
    }

    print "Velocity" at(0,24).
    print ship:groundspeed at(0,31).
    print VDOT(ErrorVector,VelocityVector) at(0,25).
    print "Vehicle Status" at(0,22).
    print Vehicle_Status at(0,23).

    //Ship
    if ALT:RADAR > 5500 {
        if targetLoad = 1 {
          set target to "DroneShip".
          SET WARP TO 0.
          wait .01.
        }
        set targetLoad to 0.

        if ALT:RADAR < 70000 AND SHIP:AIRSPEED > 1000 AND EntryBurn = 0 {
          until lngoff >= 0 {
            set driftAdjust to 0.03.
            LOCK STEERING TO LOOKDIRUP(ANGLEAXIS((-15),VCRS(-boostbackv,BODY:POSITION))*-boostbackv,FACING:TOPVECTOR).
            SET Vehicle_Status to "Status [ 4 ]".   //1=ascent 2=MECO/Stage Sep 3=Boostback 4=Entry 5=Approach 6=Landing Burn 7=Shutdown H=High Approach L=Low Approach
            AG4 on.
            set limit to 50.
            SHIP:PARTSDUBBED("fin")[0]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
            SHIP:PARTSDUBBED("fin")[1]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
            SHIP:PARTSDUBBED("fin")[2]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
            SHIP:PARTSDUBBED("fin")[3]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
            if ALT:RADAR < 55000 {
              rcs off.
              set throt to .8.
            }
          }
        }
        if SHIP:AIRSPEED < 1500 AND ALT:RADAR < 55000 AND EntryBurn = 0 {
            AG4 off.
            rcs on.
            set throt to .8.
            set driftAdjust to 0.003. //entry burn overshoot .003
            until lngoff >= 0 {
              LOCK STEERING TO LOOKDIRUP(ANGLEAXIS((-30),VCRS(-boostbackv,BODY:POSITION))*-boostbackv,FACING:TOPVECTOR).  
            }
            set accelAdjust to 2.
            set EntryBurn to 1.
            set driftAdjust to 0.001.
        }
        else {
          print lngoff at(0,34).
          print latoff at(0,35).
          AG4 off.
          if ALT:RADAR < 53000 AND ALT:RADAR > 40000 {
            set EntryBurn to 1.
            LOCK STEERING TO srfretrograde.
            SET Vehicle_Status to "Status [ H ]".  //1=ascent 2=MECO/Stage Sep 3=Boostback 4=Entry 5=Approach 6=Landing Burn 7=Shutdown H=High Approach L=Low Approach
            rcs on.
          }
          else if ALT:RADAR < 40000 {
            set EntryBurn to 1.
            if ALT:RADAR < 40000 AND ALT:RADAR > 30000 {
              rcs on.
              LOCK STEERING TO steer.
              set VectorLevel to 150000.
            }
            else if ALT:RADAR < 30000 AND ALT:RADAR > 15000 {
              rcs off.
              set VectorLevel to 100000.
            }
            else if ALT:RADAR < 15000 AND ALT:RADAR > 10000 {
              rcs off.
              set VectorLevel to 80000.
            }
            else if ALT:RADAR < 10000 {
              rcs off.
              set VectorLevel to 60000.
            }
            SET Vehicle_Status to "Status [ L ]".  //1=ascent 2=MECO/Stage Sep 3=Boostback 4=Entry 5=Approach 6=Landing Burn 7=Shutdown H=High Approach L=Low Approach
          }
          SET throt TO 0.
          if VDOT(ErrorVector,VelocityVector) > VectorLevel {
            set accelAdjust to abs(accelAdjust - .01).
          }
          else if VDOT(ErrorVector,VelocityVector) < VectorLevel {
            set accelAdjust to abs(accelAdjust + .01).
          }
          if accelAdjust > 4 {
            set accelAdjust to 4.
          }
          else if accelAdjust < .01 {
            set accelAdjust to .01.
          }
          print "Accel Adjust" at(0,27).
          print accelAdjust at(0,28).
        }
    }
    //droneship landing burn translation
    else if ALT:RADAR < 5500 AND trueRadar < stopDist {
      until ALT:RADAR < 150 {
            print "Vehicle Status" at(0,22).
            print Vehicle_Status at(0,23).
            if landingStart = 1 {
              set limit to 50.
              SHIP:PARTSDUBBED("fin")[0]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
              SHIP:PARTSDUBBED("fin")[1]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
              SHIP:PARTSDUBBED("fin")[2]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
              SHIP:PARTSDUBBED("fin")[3]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
              Set gain to -5.
              AG4 off.
              SET Vehicle_Status to "Status [6P0]".  //1=ascent 2=MECO/Stage Sep 3=Boostback 4=Entry 5=Approach 6=Landing Burn 7=Shutdown H=High Approach L=Low Approach
              rcs on.
              sas off.
              wait .1.
            }
            Set line_of_sight to target:position - ship:position.
            print lngoff at(0,34).
            print latoff at(0,35).
            set landingStart to 0.
            if ALT:RADAR < 500 {
                if landingStart2 = 1 {
                    set driftAdjust to 0.
                    gear on.
                    AG4 off.
                    set radarOffset to 36.
                }
                set landingStart2 to 0.
                if lngoff < .001 {
                  set output to -1*ship:velocity:surface*angleAxis(gain*vang(line_of_sight,ship:velocity:surface),vcrs(ship:velocity:surface,line_of_sight)).
                  Set gain to -3.
                  SET Vehicle_Status to "Status [6P3]".  //1=ascent 2=MECO/Stage Sep 3=Boostback 4=Entry 5=Approach 6=Landing Burn 7=Shutdown H=High Approach L=Low Approach
                }
                else {
                  set output to 1*ship:velocity:surface*angleAxis(gain*vang(line_of_sight,up:vector),vcrs(up:vector,line_of_sight)).
                  Set gain to 2.
                  SET Vehicle_Status to "Status [6P4]".  //1=ascent 2=MECO/Stage Sep 3=Boostback 4=Entry 5=Approach 6=Landing Burn 7=Shutdown H=High Approach L=Low Approach
                }
                lock steering to output.
            }
            else {  //Landing States
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
                Set gain to -4.
                SET Vehicle_Status to "Status [6P1]".  //1=ascent 2=MECO/Stage Sep 3=Boostback 4=Entry 5=Approach 6=Landing Burn 7=Shutdown H=High Approach L=Low Approach
              }
              else {  //pitch up from undershooting
                SET Vehicle_Status to "Status [6P2]".  //1=ascent 2=MECO/Stage Sep 3=Boostback 4=Entry 5=Approach 6=Landing Burn 7=Shutdown H=High Approach L=Low Approach
                  set output to -1*ship:velocity:surface*angleAxis(gain*vang(line_of_sight,ship:velocity:surface),vcrs(ship:velocity:surface,line_of_sight)).
                  Set gain to -5.
              }
            }
            lock steering to output.
            lock throttle to idealThrottle.
            //SET vdoutputVector TO VECDRAW(v(0,0,0),output,RGB(0,0,1),"Control",1,TRUE,0.1,TRUE).
      }
      until ship:verticalspeed > -0.1 {
          SET Vehicle_Status to "Status [6P5]".  //1=ascent 2=MECO/Stage Sep 3=Boostback 4=Entry 5=Approach 6=Landing Burn 7=Shutdown H=High Approach L=Low Approach
          set limit to 40.
          SHIP:PARTSDUBBED("fin")[0]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
          SHIP:PARTSDUBBED("fin")[1]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
          SHIP:PARTSDUBBED("fin")[2]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
          SHIP:PARTSDUBBED("fin")[3]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
          lock steering to srfretrograde.
          lock throttle to idealThrottle.        
      }
      LOCK THROTTLE TO 0.
      unlock all.
      Set RShut to 1.
    }
    else {
          set VectorLevel to 50000.
          SET Vehicle_Status to "Status [ 5l ]".
          rcs on.
          SET throt TO 0. 
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
    WAIT 0.
}

CLEARSCREEN.
SET Vehicle_Status to "Status [ 7 ]".  //1=ascent 2=MECO/Stage Sep 3=Boostback 4=Entry 5=Approach 6=Landing Burn 7=Shutdown H=High Approach L=Low Approach
print Vehicle_Status at(0,23).
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