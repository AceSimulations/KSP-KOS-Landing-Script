//FOR USE WITH ARC Max
//HS1 = Max Launch Script

CLEARSCREEN.

print "Copyright Ace Rocket Co 2021 All Rights Reserved".
print "------------------------------------------------".
wait 3.

print "Vehicle Nominal".

set INCLINATION to 90. //set Orbital inclination
print "Orbital Inclination set".

print "Starting Countdown".

//Next, we'll lock our throttle to 100%.
LOCK THROTTLE TO 0.   // 1.0 is the max, 0.0 is idle.
unlock steering.
sas off.
rcs off.

//This is our countdown loop, which cycles from 10 to 0
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
toggle AG1.
wait .5.
lock throttle to 1.

wait .5.

gear off.
wait 2.
sas off.

SET dist to 0. //loop termination
SET TargetALT TO 150000. //FINAL APOAPSIS
SET AltFlat TO TargetALT - 10000. //ALTITUDE FULLY HORIZONTAL
SET y to 90.
set speed to 30.

until SHIP:PERIAPSIS > 500 {
    print "Ascent Profile" at(0,30).
    //gravity turn
    print SHIP:APOAPSIS at(0,31).
    LOCK STEERING TO HEADING (INCLINATION,y).

    //STAGE SEPARATION
    if SHIP:APOAPSIS > 70000 AND SHIP:APOAPSIS < 71500 {
        wait 1.
        PRINT "Staging".
        lock throttle to 0.
        wait .5.
        toggle AG2.
        AG9 on.
        LOCK THROTTLE TO .01.
        wait 0.1.
        wait 3.
        PRINT "Booster Separation".
        lock throttle to 1.
        set speed to 90.
    }

    IF ALT:RADAR > 1000 { //START GRAVITY TURN
        SET y TO (90-((speed/100)*((SHIP:APOAPSIS/AltFlat)*100))). //MAIN GRAVITY TURN LOOP
        if SHIP:APOAPSIS > AltFlat { 
            SET y TO 0. //WHEN APOAPSIS WILL PASS THE AltFlat VALUE IW TILL STAY HORIZONTAL
            wait 0.
        }
        else if SHIP:APOAPSIS > TargetALT { //WHEN THE APOAPSIS PASSES YOUR DESIRED APOAPSIS IL WILL LOCK THE THROTTLE TO 0.
            LOCK steering TO HEADING(INCLINATION,0).
            lock throttle to 1.
            wait 0.
        }
        wait 0.
    }
}

//Apogee set
RCS on.
LOCK STEERING TO SHIP:VELOCITY:SURFACE.
LOCK THROTTLE to 0.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
PRINT "Apoapsis Set, lowering throttle".
print "---------------------------------------------".
print "Thank you for Flying ARC Vehicles; Your apoapsis has been set".
wait .1.
RUNPATH("0:/s3.ks").