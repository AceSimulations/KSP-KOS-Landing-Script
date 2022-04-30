//FOR USE WITH ARC ALLRS
//Logic for determining which script to run

CLEARSCREEN.

print "Copyright Ace Rocket Co 2021 All Rights Reserved".
print "------------------------------------------------".
wait .1.

if ALT:RADAR > 70000 AND SHIP:PERIAPSIS < 70000 {
    print "Vehicle Apogee set".
    RUNPATH("0:/s3.ks").
}
else if SHIP:PERIAPSIS > 70000 {
    print "Vehicle Orbit set".
    print "Please Exit program".
    wait until true.
}
else if ALT:RADAR < 1000 {
    print "Vehicle Check Complete".
    RUNPATH("0:/s1.ks").
}
else if ALT:RADAR < 70000 AND ALT:RADAR > 10000 {
    print "Landing Complete".
    RUNPATH("0:/s4.ks").
}