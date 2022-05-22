//Orbital Adjustment
print "Guidance [Converging]".
lock desired_obt_speed to sqrt(ship:body:Mu / (ship:altitude + ship:body:radius)).
lock desired_obt_vector to vxcl(-ship:body:position, ship:velocity:orbit):Normalized.
lock desired_obt_vel to (desired_obt_vector * desired_obt_speed).
lock correction_vector to (desired_obt_vel - ship:velocity:orbit).
lock STEERING to correction_vector.
sas off.
AG9 off.
wait until vang(ship:facing:forevector,correction_vector) < 5.  //wait until close to angle wanted
print "Guidance [Converged]".
until SHIP:PERIAPSIS > 100000 {
    lock THROTTLE to 1.
    print correction_vector:MAG at(0,5).
}
until (correction_vector:MAG < 1) {
    lock THROTTLE to .5.
}
lock THROTTLE to 0.
unlock steering.
sas on.
SET SASMODE TO "PROGRADE".
rcs on.
wait .5.
CLEARSCREEN.
print "Vehicle Checks [Nominal Orbit]".
Shutdown.