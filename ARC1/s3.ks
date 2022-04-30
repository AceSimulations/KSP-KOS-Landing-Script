//FOR USE WITH ARC1
//S3 = Circularization Script

CLEARSCREEN.
rcs on.
LOCK STEERING TO SHIP:VELOCITY:SURFACE.
print "Copyright Ace Rocket Co 2021 All Rights Reserved".
print "------------------------------------------------".
wait .1.

set INCLINATION to 90. //set Orbital inclination

//clearing atmosphere
UNTIL ALT:RADAR > 70000 {
    LOCK STEERING TO SHIP:VELOCITY:SURFACE.
    PRINT ROUND(SHIP:APOAPSIS,0) AT (0,16).
}.

print "Apogee Adjustment" at(0,3).
until ETA:APOAPSIS > 30 AND ETA:APOAPSIS < 60 {
    lock steering to HEADING(INCLINATION,30).
    lock throttle to 1.
    print ETA:APOAPSIS at(0,5).
    wait 0.
}

print "Circ Burn Coast" at(0,4).
toggle AG10.

//coast
lock throttle to 0.
lock BurnVector TO HEADING(INCLINATION,0).
lock steering to BurnVector.
SET TargetALT TO 150000.
SET shipMaxAcc TO SHIP:AVAILABLETHRUST / SHIP:MASS.
SET targetVel TO SQRT(CONSTANT:G * EARTH:MASS / (targetAlt + EARTH:RADIUS)).
SET burnTime TO (targetVel - Ship:VELOCITY:ORBIT:MAG) / shipMaxAcc.
SET timeToBurn TO TIME:SECONDS + ETA:APOAPSIS - (burnTime / 2).

//Orbital Insertion Burn
until ALT:APOAPSIS < ALT:PERIAPSIS + 7000 {
    print ETA:APOAPSIS AT (0,18).
    SET shipMaxAcc TO SHIP:AVAILABLETHRUST / SHIP:MASS.
    SET targetVel TO SQRT(CONSTANT:G * EARTH:MASS / (targetAlt + EARTH:RADIUS)).
    SET burnTime TO (targetVel - Ship:VELOCITY:ORBIT:MAG) / shipMaxAcc.
    SET timeToBurn TO TIME:SECONDS + ETA:APOAPSIS - (burnTime / 2).
    WHEN timeToBurn < TIME:SECONDS THEN {
        lock throttle to 1.
        print "Circ Burn" at(0,4).
        wait 0.
    }
    WHEN SHIP:PERIAPSIS > (targetAlt - 11000) THEN {
        lock throttle to 0.
        wait 0.
    }
    wait 0.
}

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