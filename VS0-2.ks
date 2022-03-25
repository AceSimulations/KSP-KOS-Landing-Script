//Stage2 Flight Profile Update
CLEARSCREEN.

if SHIP:PERIAPSIS > 140000 {
    print "Please Exit program".
    wait until true.
}
else if ALT:RADAR < 1000 {
    RUNPATH("0:/VS1.ks").
}