//S3 = Circularization Script

CLEARSCREEN.
rcs on. //proide control
LOCK STEERING TO SHIP:VELOCITY:SURFACE. //minimize drag

set INCLINATION to 90. //set Orbital inclination
SET TargetALT TO 175000.    //orbital altitude

print "Vehicle Status [C2]          " at(0,28).    //coast phase 2

//coast
LOCK throttle to 0. //SECO
LOCK BurnVector TO prograde.  //direction to burn to reach orbit
LOCK steering to BurnVector.    
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