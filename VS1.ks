//Vehicle Main Computer 1 (Use on stage 2)
CLEARSCREEN.

//Orbit Param
SET INCLINATION to 90.  //inclination
SET count to 0.         //countdown 0 = no  1 = yes
SET TargetALT TO 175000.//orbital altitude

//Init
SET AltFlat TO 175000 - 1000.   //altitude to be burning flat
SET y to 90.            //init grapvity turn pitch
SET speed to 83.        //gravity turn speed
set StageSep to 0.      //0=not staged 1=staged ------ SET TO 1 FOR EXPEND BOOSTER
SET WARPMODE TO "PHYSICS".
set sepAlt to 150000. //altitude apogee for stage separation
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
toggle AG4.  //inner engine ignition
toggle AG5.  //outer engine iginition
wait .5.
lock throttle to 1.
wait 2.
sas off.
gear off.
SET Vehicle_Status to "Status [3]". // 1=pad idle 2=verticle climb 3=gravity turn S1 4=MECO/Stage Sep 5=Gravity Turn S2
SET WARP TO 3.
set target to "DroneShip".
wait .1.
lock DronePos to Target:GEOPOSITION.
lock targetGeo TO LATLNG((DronePos:LAT),DronePos:LNG).
lock lngoff to (targetGeo:lng - addons:tr:impactpos:lng).
lock latoff to (targetGeo:lat - addons:tr:impactpos:lat).
lock boostbackv to (addons:tr:impactpos:position - targetGeo:position).


//gravity turn loop
until SHIP:APOAPSIS > TargetALT {
    print "Vehicle Status" at(0,28).
    print Vehicle_Status at(0,29). 
    print "Predicted Apogee" at(0,30).
    print SHIP:APOAPSIS at(0,31).

    if ALT:RADAR > 200 AND StageSep = 0 {
        LOCK STEERING TO LOOKDIRUP(ANGLEAXIS((y * -1),VCRS(-boostbackv,BODY:POSITION))*-boostbackv,FACING:TOPVECTOR).
    }
    else {
        LOCK STEERING TO HEADING (INCLINATION,y).
    }

    if StageSep = 0 AND lngoff <= 1 {
        SET WARP TO 0.
    }

    //STAGE SEPARATION
    if StageSep = 0 AND lngoff <= 0 {
        LOCK STEERING TO LOOKDIRUP(ANGLEAXIS((y * -1),VCRS(boostbackv,BODY:POSITION))*boostbackv,FACING:TOPVECTOR).
        lock throttle to .5.
        wait until lngoff <= -0.18.   //MAIN OVERSHOOT
        unlock steering.
        sas on.
        SET Vehicle_Status to "Status [4]". // 1=pad idle 2=verticle climb 3=gravity turn S1 4=MECO/Stage Sep 5=Gravity Turn S2
        lock throttle to 0.     //MECO
        wait 1.
        AG9 on.
        set StageSep to 1.
        wait 1.
        SET AltFlat TO TargetALT - 1000.   //altitude to be burning flat
        SET y TO (90-((speed/100)*((SHIP:APOAPSIS/AltFlat)*100))).
        set speed to 99.
        sas off.
        rcs on.
        toggle AG1.
        toggle AG2.
        wait 3.
        lock throttle to 1.
        unlock lngoff.
        unlock latoff.
        unlock boostbackv.
        SET Vehicle_Status to "Status [5]".  // 1=pad idle 2=verticle climb 3=gravity turn S1 4=MECO/Stage Sep 5=Gravity Turn S2
    }

    if ALT:RADAR > 80000 AND ALT:RADAR < 85000 {
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
if SHIP:PERIAPSIS < 145000 {
    RUNPATH("0:/OA.ks").
}
else {
    SHUTDOWN.
}