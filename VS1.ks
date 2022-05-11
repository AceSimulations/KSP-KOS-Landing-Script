//Vehicle Main Computer 1 (Use on stage 2)
CLEARSCREEN.

//Orbit Param
SET INCLINATION to 90.  //inclination   NOTE: CAN ONLY BE 90 IF DSL (Droneship landing)
//NOTE: IF INCLINATION OTHER THAN 90 Must Boostback to LS
SET TargetALT TO 250000.//orbital altitude  250km
SET count to 1.         //countdown 0 = no  1 = yes
//Init
SET AltFlat TO 200000.   //altitude to be burning flat   200km
SET y to 90.            //init grapvity turn pitch
SET speed to 80.        //gravity turn speed
set StageSep to 0.      //0=not staged 1=staged
lock g to constant:g * body:mass / body:radius^2. // Gravity (m/s^2)
lock TWRThrot to 5 * Ship:Mass * g / Ship:AvailableThrust.  //Throttle to maintain TWR
SET WARPMODE TO "PHYSICS".  //Allow warping
SET Vehicle_Status to "Status [1]".            // 1=pad idle 2=verticle climb 3=gravity turn S1 4=MECO/Stage Sep 5=Gravity Turn S2
print "Vehicle Status" at(0,28).
print Vehicle_Status at(0,29).
LOCK THROTTLE TO 0.
unlock steering.
sas off.
rcs off.

//countdown
if count = 1 {  //It is a countdown that will cycle throttle because why not
    PRINT "Time To Liftoff:".
    print "T-10".
    wait 1.
    print "T-9".
    wait 1.
    print "T-8".
    wait 1.
    print "T-7".
    wait 1.
    print "T-6".
    LOCK THROTTLE TO .2.
    wait 1.
    print "T-5".
    sas on.
    wait 1.
    print "T-4".
    wait 1.
    print "T-3".
    wait 1.
    print "T-2".
    wait .5.
    lock throttle to 1.
    wait .5.
    print "T-1".
}
//immediate launch
else if count = 0 { //no countdown and configure vehicle for launch
    sas on.
    lock throttle to 0.
    wait 1.
}

//launch command
SET Vehicle_Status to "Status [2]".  // 1=pad idle 2=verticle climb 3=gravity turn S1 4=MECO/Stage Sep 5=Gravity Turn S2
print "Vehicle Status" at(0,28).
print Vehicle_Status at(0,29).
AG4 on.  //outer 1 engine ignition
AG5 on.  //inner 2 engine iginition
AG6 on.  //outer engine iginition
lock throttle to TWRThrot. //Liftoff Command
wait 3.
Toggle ag8. //Release Clamps
sas off.    //prevent conflicting control
wait 1.
set target to "DroneShip".
wait .1.
lock DronePos to Target:GEOPOSITION.    //Geo LAT, LNG coordinates
lock targetGeo TO LATLNG((DronePos:LAT),(DronePos:LNG + 1)).    //Target Adjustment
lock lngoff to (targetGeo:lng - addons:tr:impactpos:lng).   //Difference between predicted impact and target
lock latoff to (targetGeo:lat - addons:tr:impactpos:lat).   //Nobody cares about lat but I will use it anyway
lock boostbackv to (addons:tr:impactpos:position - targetGeo:position). //Parallel vector to vector between impact and target location
SET Vehicle_Status to "Status [3]". // 1=pad idle 2=verticle climb 3=gravity turn S1 4=MECO/Stage Sep 5=Gravity Turn S2
SET WARP TO 3.  //Speed up flight profile

if INCLINATION = 90 {
    set speed to 80.
}
else {
    set speed to 60.
}

//gravity turn loop
until SHIP:APOAPSIS > TargetALT {   
    print "Vehicle Status" at(0,28).
    print Vehicle_Status at(0,29). 
    print "Predicted Apogee" at(0,30).
    print SHIP:APOAPSIS at(0,31).

    if ALT:RADAR > 200 AND StageSep = 0 AND INCLINATION = 90 {  //control to be heading to droneship
        LOCK STEERING TO LOOKDIRUP(ANGLEAXIS((y * -1),VCRS(-boostbackv,BODY:POSITION))*-boostbackv,FACING:TOPVECTOR).
    }
    else {  //control to inclination direction
        LOCK STEERING TO HEADING (INCLINATION,y).
    }

    //Stage Separation
    if INCLINATION = 90 {
        if StageSep = 0 AND lngoff <= 1.2 { //Stop warping and stablize
            SET WARP TO 0.
            rcs on.
            lock throttle to .7.    //throttle down for MECO/Stage Sep
        }
        if StageSep = 0 AND lngoff <= .85 {
            lock throttle to 0.     //MECO
            SET Vehicle_Status to "Status [4]". // 1=pad idle 2=verticle climb 3=gravity turn S1 4=MECO/Stage Sep 5=Gravity Turn S2
            wait 1.
            AG9 on. //Stage Sep
            set StageSep to 1.
            SET AltFlat TO TargetALT - 1000.   //altitude to be burning flat
            SET y TO (90-((speed/100)*((SHIP:APOAPSIS/AltFlat)*100))).
            set speed to 99.    //increase rate of turn in gravity turn
            LOCK STEERING TO HEADING (INCLINATION,y).
            print ship:mass.
            lock throttle to 1.
            unlock lngoff.
            unlock latoff.
            unlock boostbackv.
            SET Vehicle_Status to "Status [5]".  // 1=pad idle 2=verticle climb 3=gravity turn S1 4=MECO/Stage Sep 5=Gravity Turn S2
        }
    }
    else {
        if StageSep = 0 AND SHIP:AIRSPEED > 1400 {  //Stop warping and stablize
            SET WARP TO 0.
            rcs on.
            lock throttle to .7.    //throttle down for MECO/Stage Sep
            sas on.
            unlock steering.
        }
        if StageSep = 0 AND SHIP:AIRSPEED > 1600 {
            lock throttle to 0.     //MECO
            SET Vehicle_Status to "Status [4]". // 1=pad idle 2=verticle climb 3=gravity turn S1 4=MECO/Stage Sep 5=Gravity Turn S2
            wait 1.
            AG9 on. //Stage Sep
            set StageSep to 1.
            SET AltFlat TO TargetALT - 1000.   //altitude to be burning flat
            SET y TO (90-((speed/100)*((SHIP:APOAPSIS/AltFlat)*100))).
            set speed to 99.    //increase rate of turn in gravity turn
            LOCK STEERING TO HEADING (INCLINATION,y).
            sas off.
            print ship:mass.
            lock throttle to 1.
            unlock lngoff.
            unlock latoff.
            unlock boostbackv.
            SET Vehicle_Status to "Status [5]".  // 1=pad idle 2=verticle climb 3=gravity turn S1 4=MECO/Stage Sep 5=Gravity Turn S2
        }
    }

    if ALT:RADAR > 85000 AND ALT:RADAR < 90000 {    //Release Fairings
        AG7 on.
    }

    IF ALT:RADAR > 200 {    //Gravity turn calculation
        SET y TO (90-((speed/100)*((SHIP:APOAPSIS/AltFlat)*100))).
        if SHIP:APOAPSIS > AltFlat { 
            SET y TO 0.
        }
        else if SHIP:APOAPSIS > TargetALT {
            LOCK steering TO HEADING(INCLINATION,0).
        }
        wait 0.
    }
}
SET WARP TO 0.
RCS on.
sas off.
unlock steering.
LOCK THROTTLE to 0.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
RUNPATH("0:/OA.ks").