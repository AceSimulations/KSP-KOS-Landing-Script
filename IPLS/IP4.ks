set INCLINATION to 90. //set Orbital inclination

CLEARSCREEN.
print "Rentry Attitude".
set limit to 0.
SHIP:PARTSDUBBED("cbf")[0]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
SHIP:PARTSDUBBED("cbf")[1]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
SHIP:PARTSDUBBED("cbf")[2]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
SHIP:PARTSDUBBED("cbf")[3]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
sas off.
lock steering to prograde.
print "Brake Deploy [NOMINAL]".
toggle AG6.
brakes on.
rcs on.
print "Approaching" AT(0,32).
wait until SHIP:AIRSPEED < 1500.
set limit to 40.
SHIP:PARTSDUBBED("cbf")[0]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
SHIP:PARTSDUBBED("cbf")[1]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
SHIP:PARTSDUBBED("cbf")[2]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
SHIP:PARTSDUBBED("cbf")[3]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).

set radarOffset to 14.	 				// The value of alt:radar when landed (on gear)
lock trueRadar to alt:radar - radarOffset.			// Offset radar to get distance from gear to ground
lock g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)
lock maxDecel to ((ship:availablethrust - 1000) / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
lock stopDist to ship:verticalspeed^2 / (2 * maxDecel).		// The distance the burn will require
lock idealThrottle to (stopDist / trueRadar) * 1.1.			// Throttle required for perfect hoverslam
lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact, used for landing gear
lock reorientAlt to stopDist + 5000.
lock adjustAlt to stopDist + 500.

wait until trueRadar < reorientAlt.
LOCK STEERING TO up.
brakes off.
print "Gear Deploy [NOMINAL]".
toggle AG8.
print "Startup [NOMINAL]".
sas off.

set limit to 20.
SHIP:PARTSDUBBED("cbf")[0]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
SHIP:PARTSDUBBED("cbf")[1]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
SHIP:PARTSDUBBED("cbf")[2]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).
SHIP:PARTSDUBBED("cbf")[3]:GETMODULE("ModuleControlSurface"):setfield("authority limiter", limit).

print "Transfering Fuel".
SET header to SHIP:PARTSDUBBED("Header").
SET ox to SHIP:PARTSDUBBED("OxTank").
SET base to SHIP:PARTSDUBBED("Base").

wait .1.
SET LF1 TO TRANSFERALL("LiquidFuel", header, base).
SET LF2 TO TRANSFERALL("LiquidFuel", ox, base).
wait .1.
SET LF1:ACTIVE to TRUE.
SET LF2:ACTIVE to TRUE.
print "Liguid Fuel Transfer Complete".
wait .1.

SET OX1 TO TRANSFERALL("OXIDIZER", ox, base).
wait .1.
SET OX1:ACTIVE to TRUE.
print "Oxidizer Fuel Transfer Complete".
wait 1.

WAIT UNTIL trueRadar < AdjustAlt.
		LOCK STEERING TO (-1) * SHIP:VELOCITY:SURFACE.
		lock throttle to 1.
		wait until SHIP:GROUNDSPEED < 20 OR trueRadar < stopDist.

lock throttle to 0.
lock steering to srfretrograde.

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
	lock throttle to 0.
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
print "ARC IP4 Will now Exit".
SHUTDOWN.