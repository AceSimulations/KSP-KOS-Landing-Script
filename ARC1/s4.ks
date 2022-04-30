set INCLINATION to 90. //set Orbital inclination

CLEARSCREEN.
print "Rentry Attitude".
sas off.
lock steering to up.
rcs on.
wait until ALT:RADAR < 40000.
sas off.
rcs on.
lock steering to srfretrograde.
wait until ALT:RADAR < 30000.
print "Brake Deploy [NOMINAL]".
toggle AG6.
wait until ALT:RADAR < 26000.
lock throttle to .5.
wait until SHIP:GROUNDSPEED < 1650.
lock throttle to 0.
wait until ALT:RADAR < 10000.
print "Gear Deploy [NOMINAL]".
gear on.
lock steering to up.
wait until ALT:RADAR < 4000.
print "Landing Burn Startup".
lock throttle to .07.
wait .1.
sas off.
rcs off.
print "Approaching" AT(0,32).
wait 1.

CLEARSCREEN.
print "Startup [NOMINAL]".
set radarOffset to 18.9.	 				// The value of alt:radar when landed (on gear)
lock trueRadar to alt:radar - radarOffset.			// Offset radar to get distance from gear to ground
lock g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)
lock maxDecel to ((ship:availablethrust - 1000) / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
lock stopDist to ship:verticalspeed^2 / (2 * maxDecel).		// The distance the burn will require
lock idealThrottle to (stopDist / trueRadar) * 1.1.			// Throttle required for perfect hoverslam
lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact, used for landing gear

WAIT UNTIL ship:verticalspeed < -1.
	print "Landing Burn F1 [Nominal]".
	sas off.

WAIT UNTIL trueRadar < stopDist.
	set limit to 0.
	SHIP:PARTSDUBBED("cbf")[0]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
	SHIP:PARTSDUBBED("cbf")[1]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
	SHIP:PARTSDUBBED("cbf")[2]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
  SHIP:PARTSDUBBED("cbf")[3]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
	print "Landing Burn F2 [Nominal]".
	lock throttle to idealThrottle.
	lock steering to srfretrograde.

WAIT UNTIL ship:verticalspeed > -0.01.
	print "Landing Burn [Nominal]".
	set ship:control:pilotmainthrottle to 0.
	rcs off.

PRINT "ENGINE SHUTDOWN".
wait .5.
PRINT "GIMBAL LOCKED".
LOCK THROTTLE TO 0.
WAIT 3.
sas off.
UNLOCK STEERING.
rcs on.
sas off.
lock steering to up.
wait 2.
rcs off.
lock throttle to 0.
toggle AG6.
lights off.
unlock throttle.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
print "Handing Rocket Control over to Manual Control".
wait 1.
print "Vehicle Ready for Recovery".
print "---------------------------------------".
print "ARC S4 Will now Exit".
SHUTDOWN.