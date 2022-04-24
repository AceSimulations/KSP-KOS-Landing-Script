//Vehicle Main Computer 1 (Use on stage 2)
CLEARSCREEN.

//Orbit Param
SET INCLINATION to 90.  //inclination   
//NOTE: IF INCLINATION OTHER THAN 90 Must Boostback to LS
SET TargetALT TO 250000.//orbital altitude  250km
SET count to 0.         //countdown 0 = no  1 = yes
//Init
SET AltFlat TO 200000.   //altitude to be burning flat   200km
SET y to 90.            //init grapvity turn pitch
SET speed to 80.        //gravity turn speed
set StageSep to 0.      //0=not staged 1=staged
lock g to constant:g * body:mass / body:radius^2. // Gravity (m/s^2)
lock TWRThrot to 3.5 * Ship:Mass * g / Ship:AvailableThrust.  //Throttle to maintain TWR
SET WARPMODE TO "PHYSICS".
SET Vehicle_Status to "Status [1]".            // 1=pad idle 2=verticle climb 3=gravity turn S1 4=MECO/Stage Sep 5=Gravity Turn S2
print "Vehicle Status" at(0,28).
print Vehicle_Status at(0,29).
LOCK THROTTLE TO 0.
unlock steering.
sas off.
rcs off.

//countdown
if count = 1 {
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
    lock throttle to 0.
    wait .5.
    print "T-1".
}
//immediate launch
else if count = 0 {
    sas on.
    lock throttle to 0.
    wait 1.
}

//launch command
SET Vehicle_Status to "Status [2]".  // 1=pad idle 2=verticle climb 3=gravity turn S1 4=MECO/Stage Sep 5=Gravity Turn S2
print "Vehicle Status" at(0,28).
print Vehicle_Status at(0,29).
AG4 on.  //outer engine ignition
AG5 on.  //inner engine iginition
wait .5.
lock throttle to TWRThrot. //Liftoff Command
wait 2.
sas off.
gear off.
SET WARP TO 3.
set target to "DroneShip".
wait .1.
lock DronePos to Target:GEOPOSITION.    //Geo LAT, LNG coordinates
lock targetGeo TO LATLNG((DronePos:LAT),(DronePos:LNG + 1)).    //Target Adjustment
lock lngoff to (targetGeo:lng - addons:tr:impactpos:lng).   //Difference between predicted impact and target
lock latoff to (targetGeo:lat - addons:tr:impactpos:lat).   //Nobody cares about lat but I will use it anyway
lock boostbackv to (addons:tr:impactpos:position - targetGeo:position). //Parallel vector to vector between impact and target location
SET Vehicle_Status to "Status [3]". // 1=pad idle 2=verticle climb 3=gravity turn S1 4=MECO/Stage Sep 5=Gravity Turn S2

//gravity turn loop
until SHIP:APOAPSIS > TargetALT {
    print "Vehicle Status" at(0,28).
    print Vehicle_Status at(0,29). 
    print "Predicted Apogee" at(0,30).
    print SHIP:APOAPSIS at(0,31).

    if ALT:RADAR > 200 AND StageSep = 0 AND INCLINATION = 90 {
        LOCK STEERING TO LOOKDIRUP(ANGLEAXIS((y * -1),VCRS(-boostbackv,BODY:POSITION))*-boostbackv,FACING:TOPVECTOR).
    }
    else {
        LOCK STEERING TO HEADING (INCLINATION,y).
    }

    if INCLINATION = 90 {
        if StageSep = 0 AND lngoff <= 1.5 {
        SET WARP TO 0.
        }
    }
    else {
        if StageSep = 0 AND SHIP:AIRSPEED > 1500 {
        SET WARP TO 0.
        }
    }

    //STAGE SEPARATION
    if INCLINATION = 90 {
        if StageSep = 0 AND lngoff <= .9 {
            lock throttle to 0.     //MECO
            unlock steering.
            sas on.
            SET Vehicle_Status to "Status [4]". // 1=pad idle 2=verticle climb 3=gravity turn S1 4=MECO/Stage Sep 5=Gravity Turn S2
            wait 1.
            AG9 on.
            set StageSep to 1.
            sas off.
            LOCK STEERING TO HEADING (INCLINATION,y).
            rcs on.
            wait 2.
            SET AltFlat TO TargetALT - 1000.   //altitude to be burning flat
            SET y TO (90-((speed/100)*((SHIP:APOAPSIS/AltFlat)*100))).
            set speed to 99.
            print ship:mass.
            AG1 on.
            AG2 on.
            wait 2.
            lock throttle to 1.
            unlock lngoff.
            unlock latoff.
            unlock boostbackv.
            SET Vehicle_Status to "Status [5]".  // 1=pad idle 2=verticle climb 3=gravity turn S1 4=MECO/Stage Sep 5=Gravity Turn S2
        }
    }
    else {
        if StageSep = 0 AND SHIP:AIRSPEED > 1800 {
            lock throttle to 0.     //MECO
            unlock steering.
            sas on.
            SET Vehicle_Status to "Status [4]". // 1=pad idle 2=verticle climb 3=gravity turn S1 4=MECO/Stage Sep 5=Gravity Turn S2
            wait 1.
            AG9 on.
            set StageSep to 1.
            sas off.
            LOCK STEERING TO HEADING (INCLINATION,y).
            rcs on.
            wait 2.
            SET AltFlat TO TargetALT - 1000.   //altitude to be burning flat
            SET y TO (90-((speed/100)*((SHIP:APOAPSIS/AltFlat)*100))).
            set speed to 99.
            print ship:mass.
            AG1 on.
            AG2 on.
            wait 2.
            lock throttle to 1.
            unlock lngoff.
            unlock latoff.
            unlock boostbackv.
            SET Vehicle_Status to "Status [5]".  // 1=pad idle 2=verticle climb 3=gravity turn S1 4=MECO/Stage Sep 5=Gravity Turn S2
        }
    }

    if ALT:RADAR > 85000 AND ALT:RADAR < 90000 {
        AG7 on.
    }

    IF ALT:RADAR > 200 {
        SET y TO (90-((speed/100)*((SHIP:APOAPSIS/AltFlat)*100))).
        if SHIP:APOAPSIS > AltFlat { 
            SET y TO 0.
        }
        else if SHIP:APOAPSIS > TargetALT {
            LOCK steering TO HEADING(INCLINATION,0).
            lock throttle to 1.
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