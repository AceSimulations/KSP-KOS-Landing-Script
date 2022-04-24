//Orbital Adjustment
lock desired_obt_speed to sqrt(ship:body:Mu / (ship:altitude + ship:body:radius)).
lock desired_obt_vector to vxcl(-ship:body:position, ship:velocity:orbit):Normalized.
lock desired_obt_vel to (desired_obt_vector * desired_obt_speed).
lock correction_vector to (desired_obt_vel - ship:velocity:orbit).
lock STEERING to correction_vector.
wait 5.
until SHIP:PERIAPSIS > 100000 {
    lock THROTTLE to .3.
    print correction_vector:MAG at(0,5).
}
until (correction_vector:MAG < 1) {
    lock THROTTLE to .1.
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