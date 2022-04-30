////FOR USE WITH V4 ARC ORBIT VEHICLES
CLEARSCREEN.

print "Copyright Ace Rocket Co 2021 All Rights Reserved".
print "------------------------------------------------".

//Next, we'll lock our throttle to 100%.
LOCK THROTTLE TO 1.   // 1.0 is the max, 0.0 is idle.

//This is our countdown loop, which cycles from 10 to 0
PRINT "Time To Liftoff:".
FROM {local countdown is 10.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    PRINT "T-" + countdown.
    WAIT 1. 
}

//launch command
stage.
wait 1.
gear off.

//This will be our main control loop for the ascent. It will cycle through continuously until our apoapsis is greater than 100km. Each cycle, it will check each of the IF statements inside and perform them if their conditions are met
SET MYSTEER TO HEADING(90,90).
LOCK STEERING TO MYSTEER. // from now on we'll be able to change steering by just assigning a new value to MYSTEER
UNTIL SHIP:APOAPSIS > 122000 { //Remember, all altitudes will be in meters, not kilometers

    //For the initial ascent, we want our steering to be straight
    //up and rolled due east
    IF SHIP:VELOCITY:SURFACE:MAG < 100 {
        //This sets our steering 90 degrees up and yawed to the compass
        //heading of 90 degrees (east)
        SET MYSTEER TO HEADING(90,90).

    //Once we pass 100m/s, we want to pitch down ten degrees
    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 100 AND SHIP:VELOCITY:SURFACE:MAG < 150 {
        SET MYSTEER TO HEADING(90,85).
        PRINT "Pitching to 85 degrees" AT(0,15).
        PRINT ROUND(SHIP:APOAPSIS,0) AT (0,16).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 150 AND SHIP:VELOCITY:SURFACE:MAG < 200 {
        SET MYSTEER TO HEADING(90,80).
        PRINT "Pitching to 80 degrees" AT(0,15).
        PRINT ROUND(SHIP:APOAPSIS,0) AT (0,16).

    //Each successive IF statement checks to see if our velocity
    //is within a 100m/s block and adjusts our heading down another
    //ten degrees if so
    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 200 AND SHIP:VELOCITY:SURFACE:MAG < 250 {
        SET MYSTEER TO HEADING(90,75).
        PRINT "Pitching to 75 degrees" AT(0,15).
        PRINT ROUND(SHIP:APOAPSIS,0) AT (0,16).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 250 AND SHIP:VELOCITY:SURFACE:MAG < 300 {
        SET MYSTEER TO HEADING(90,70).
        PRINT "Pitching to 70 degrees" AT(0,15).
        PRINT ROUND(SHIP:APOAPSIS,0) AT (0,16).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 300 AND SHIP:VELOCITY:SURFACE:MAG < 350 {
        SET MYSTEER TO HEADING(90,65).
        PRINT "Pitching to 65 degrees" AT(0,15).
        PRINT ROUND(SHIP:APOAPSIS,0) AT (0,16).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 350 AND SHIP:VELOCITY:SURFACE:MAG < 400 {
        SET MYSTEER TO HEADING(90,60).
        PRINT "Pitching to 60 degrees" AT(0,15).
        PRINT ROUND(SHIP:APOAPSIS,0) AT (0,16).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 400 AND SHIP:VELOCITY:SURFACE:MAG < 450 {
        SET MYSTEER TO HEADING(90,55).
        PRINT "Pitching to 55 degrees" AT(0,15).
        PRINT ROUND(SHIP:APOAPSIS,0) AT (0,16).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 450 AND SHIP:VELOCITY:SURFACE:MAG < 500 {
        SET MYSTEER TO HEADING(90,50).
        PRINT "Pitching to 50 degrees" AT(0,15).
        PRINT ROUND(SHIP:APOAPSIS,0) AT (0,16).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 500 AND SHIP:VELOCITY:SURFACE:MAG < 550 {
        SET MYSTEER TO HEADING(90,45).
        PRINT "Pitching to 45 degrees" AT(0,15).
        PRINT ROUND(SHIP:APOAPSIS,0) AT (0,16).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 550 AND SHIP:VELOCITY:SURFACE:MAG < 600 {
        SET MYSTEER TO HEADING(90,40).
        PRINT "Pitching to 40 degrees" AT(0,15).
        PRINT ROUND(SHIP:APOAPSIS,0) AT (0,16).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 600 AND SHIP:VELOCITY:SURFACE:MAG < 650 {
        SET MYSTEER TO HEADING(90,35).
        PRINT "Pitching to 35 degrees" AT(0,15).
        PRINT ROUND(SHIP:APOAPSIS,0) AT (0,16).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 650 AND SHIP:VELOCITY:SURFACE:MAG < 700 {
        SET MYSTEER TO HEADING(90,30).
        PRINT "Pitching to 30 degrees" AT(0,15).
        PRINT ROUND(SHIP:APOAPSIS,0) AT (0,16).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 700 AND SHIP:VELOCITY:SURFACE:MAG < 750 {
        SET MYSTEER TO HEADING(90,25).
        PRINT "Pitching to 25 degrees" AT(0,15).
        PRINT ROUND(SHIP:APOAPSIS,0) AT (0,16).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 750 AND SHIP:VELOCITY:SURFACE:MAG < 800 {
        SET MYSTEER TO HEADING(90,20).
        PRINT "Pitching to 20 degrees" AT(0,15).
        PRINT ROUND(SHIP:APOAPSIS,0) AT (0,16).

    //Beyond 800m/s, we can keep facing towards 10 degrees above the horizon and wait
    //for the main loop to recognize that our apoapsis is above 100km
    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 800 {
        SET MYSTEER TO HEADING(90,10).
        PRINT "Pitching to 10 degrees" AT(0,15).
        PRINT ROUND(SHIP:APOAPSIS,0) AT (0,16).

    }.

}.

//Apogee set
LOCK THROTTLE to 0.
PRINT "100km apoapsis reached, lowering throttle".
RCS on.

//clearing atmosphere
UNTIL ALT:RADAR > 70000 {
lock steering to prograde.
PRINT ROUND(SHIP:APOAPSIS,0) AT (0,16).
}.

//coast
lock throttle to 0.
SET MYSTEER TO HEADING(90,0).

//Orbital Insertion Burn
UNTIL ALT:PERIAPSIS > 120000 {
    print ETA:APOAPSIS.
    IF ETA:APOAPSIS < 3 {
        lock throttle to 1.
        until ALT:PERIAPSIS > 120000 {
	     print "Accelerating to Orbital Velocity".
        }.
    }.
    ELSE {
        lock throttle to 0.
    }.
}.
print "--------------------------".
print "Orbit Nominal".

//At this point, our apoapsis is above 100km and our main loop has ended. Next
//we'll make sure our throttle is zero and that we're pointed prograde
LOCK THROTTLE TO 0.

//This sets the user's throttle setting to zero to prevent the throttle
//from returning to the position it was at before the script was run.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
print "---------------------------------------------".
print "Thank you for Flying ARC Vehicles; You have reached Orbit".
wait 2.
print "Orbital Script has exited".
print "Next Script Landing.ks".
wait 1.
print "Handing Rocket Control over to Manual Control".