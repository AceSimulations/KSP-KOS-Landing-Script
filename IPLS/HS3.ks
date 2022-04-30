//S3 = Circularization Script

CLEARSCREEN.    //clear CPU data cash
rcs on. //proide control
LOCK STEERING TO SHIP:VELOCITY:SURFACE. //minimize drag
print "Copyright Ace Rocket Co 2021 All Rights Reserved".
print "------------------------------------------------".
wait .1.

set INCLINATION to 90. //set Orbital inclination

print "Vehicle Status [C1]           " at(0,28).    //coast phase 1

//clearing atmosphere
UNTIL ALT:RADAR > 70000 {
    LOCK STEERING TO SHIP:VELOCITY:SURFACE.
    PRINT ROUND(SHIP:APOAPSIS,0) AT (0,16).
}.

//adjust apogee if arrive after apogee has been passed
print "Vehicle Status [SESU1]        " at(0,28).
print "Apogee Adjustment" at(0,3).
until ETA:APOAPSIS > 30 AND ETA:APOAPSIS < 100 {
    lock steering to HEADING(INCLINATION,30).   //burn up at angle to push Apogee in front of vehicle
    lock throttle to 1.
    print ETA:APOAPSIS at(0,5).
    wait 0.
}

print "Vehicle Status [C2]          " at(0,28).    //coast phase 2
toggle AG10.    //deploy solar panels and antenna
brakes on.

//coast
LOCK throttle to 0. //SECO
LOCK BurnVector TO prograde.  //direction to burn to reach orbit
LOCK steering to BurnVector.    
SET TargetALT TO 150000.    //orbital altitude
LOCK shipMaxAcc TO SHIP:AVAILABLETHRUST / SHIP:MASS. //calculate acceleration
LOCK targetVel TO SQRT(CONSTANT:G * EARTH:MASS / (targetAlt + EARTH:RADIUS)).    //calculate orbital velocity
LOCK burnTime TO (targetVel - Ship:VELOCITY:ORBIT:MAG) / shipMaxAcc. //calculate time to reach orbital veloctiy
LOCK timeToBurn TO TIME:SECONDS + ETA:APOAPSIS - (burnTime / 2).    //calculate time until starting circ burn

wait until timeToBurn < TIME:SECONDS.

//Orbital Insertion Burn
print "Vehicle Status [SESU2]              " at(0,28).
lock throttle to 1. //Circ Burn Startup

until burnTime < .01 {
    print SHIP:APOAPSIS at(0,5).
    print SHIP:PERIAPSIS at(0,6).
    wait 0.
}

lock throttle to 0. //engine shutdown
print "Vehicle Status [SECO]                " at(0,28).

wait 1.
CLEARSCREEN.
print "--------------------------".
print "Orbit Nominal".

LOCK THROTTLE TO 0.

//This sets the user's throttle setting to zero to prevent the throttle
//from returning to the position it was at before the script was run.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
print "---------------------------------------------".
print "Thank you for Flying ARC Vehicles; You have reached Orbit".
wait 2.
AG2 on.
print "Orbital Script has exited".
wait 1.
print "Handing Rocket Control over to Manual Control".
SHUTDOWN.