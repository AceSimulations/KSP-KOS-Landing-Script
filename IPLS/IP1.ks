//FOR USE WITH IPLS
//HS1 = IPLS Launch

CLEARSCREEN.
print "Copyright Ace Rocket Co 2021 All Rights Reserved".
print "------------------------------------------------".
wait 1.
print "Vehicle Status [Init]   " at(0,28).

set INCLINATION to 90. //set Orbital inclination
print "Orbital Inclination set to " + INCLINATION.

//setting vehicle to proper liftoff state
print "Vehicle Status [Nominal]" at(0,28).
LOCK THROTTLE TO 0.
unlock steering.
sas off.
rcs off.

//enable countdown
set count to 1.
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
    LOCK THROTTLE TO .2.    //ensure good throttle control
    wait 1.
    print "T-5".
    sas on.                 //prep for liftoff
    wait 1.
    print "T-4".
    wait 1.
    print "T-3".
    wait 1.
    print "T-2".
    wait .5.
    lock throttle to 0.     //prep for ignition
    wait .5.
    print "T-1".
}
//bypass countdown
else if count = 0 {
    sas on.             //init liftoff control
    lock throttle to 0. //prep for ignition
    wait 1.
}
toggle AG4.  
toggle AG5.            //engine ignition
wait .5.
lock throttle to 1.     //liftoff
wait 2.
sas off.                //prep for active control
gear off.       //landing legs retract
print "Vehicle Status [G1]          " at(0,28).

SET TargetALT TO 150000. //FINAL APOAPSIS
SET AltFlat TO TargetALT - 10000. //ALTITUDE FULLY HORIZONTAL
SET y to 90.           //pitch angle
set speed to 58.        //indirectly changes downrange pitch veloctiy 

until SHIP:PERIAPSIS > 100 {    //wait until nearing orbit velocity for coast
    print "Predicted Apogee" at(0,30).
    print SHIP:APOAPSIS at(0,31).       //reads out apogee value
    LOCK STEERING TO HEADING (INCLINATION,y).   //steers along set gravity turn

    //STAGE SEPARATION
    if SHIP:APOAPSIS > 70000 AND SHIP:APOAPSIS < 71500 {
        wait 1.
        print "Vehicle Status [S1]            " at(0,28).
        lock throttle to 0.     //MECO
        wait .5.
        toggle AG2.             //Second stage prep for ignition
        AG9 on.         //stage separation
        wait 0.1.
        wait 5.
        print "Vehicle Status [S2]             " at(0,28).
        lock throttle to 1.     //second stage ignition
        set speed to 90.        //increase pitch for gravity turn
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

//Coast Phase
RCS on.
LOCK STEERING TO SHIP:VELOCITY:SURFACE. //minimize drag in upper atmosphere
LOCK THROTTLE to 0.     //SECO
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
PRINT "Apoapsis Set, Entering Coast Phase".
print "---------------------------------------------".
print "Thank you for Flying ARC Vehicles; Your apoapsis has been set".
wait .1.
RUNPATH("0:/HS3.ks").