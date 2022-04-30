//FOR USE WITH V4 ARC ORBIT VEHICLES
CLEARSCREEN.
SET spot TO LATLNG(10, 20).
PRINT spot:LAT.                 // Print 10
PRINT spot:LNG.                 // Print 20
print "Starting Landing.ks".
wait 2.

//Deorbit Script
print "------------------------------------------------".
print "Rocket will Deorbit for landing at KSC".
rcs on.
sas off.
lock steering to retrograde.
print "Preping for Deorbit Burn".
wait 5.
until spot:LNG > 160 {
	SET spot TO SHIP:GEOPOSITION. 
	PRINT spot:LNG.
}.

//Find deorbit location
PRINT "Default Deorbit Init".
SET spot TO LATLNG(10, 20).
PRINT spot:LAT.                 // Print 10
PRINT spot:LNG.                 // Print 20
PRINT "Setting Deorbit Current Position".
SET spot TO SHIP:GEOPOSITION. 
PRINT spot:LAT.
PRINT spot:LNG.
print "Finding Deorbit solution".
wait 5.

print "Deorbit Solution found and is Nominal".
until spot:LNG > 179 {
	SET spot TO SHIP:GEOPOSITION. 
	PRINT spot:LNG.
}.
print "logging pre Deorbit Data".
wait 15.
SET spot TO SHIP:GEOPOSITION. 
until spot:LNG > -160.5 {
	SET spot TO SHIP:GEOPOSITION. 
	PRINT spot:LNG.
}.

print "Deorbit Location reached".
SET spot TO SHIP:GEOPOSITION. 
PRINT spot:LNG.
wait 1.
UNTIL ALT:Periapsis < 50 {
lock throttle to 1.
print "Slowing".
}.
wait 1.
lock throttle to 0.
CLEARSCREEN.
print "Deorbit burn nominal".
wait 1.
print "Deorbit Script has exited".
print "Next Script landing.ks".
wait 1.
print "Starting landing.ks".
wait 2.

CLEARSCREEN.
//landing burn/script
set target to "KSC".
print "Target Set".
lock steering to up.
print "Preparing for Landing Burn".
wait 1.
until ALT:RADAR < 21000 {
  if ALT:RADAR < 48000 {
    LOCK STEERING TO retrograde. 
  }.
  if ALT:RADAR < 36000 {
      if SHIP:GROUNDSPEED > 1800 {
        lock throttle to 1.
      }.
      if SHIP:GROUNDSPEED < 1800 {
        lock throttle to 0.
      }.
    }.
    print "Rentry".
}.
brakes on.
print "Brake Deployed".
list engines in engs.
for eng in engs {
    if eng:ignition {
        set eng:gimbal:limit to 40.
    }
}.
lock steering to retrograde.
until ALT:RADAR < 2000 {
print target:distance.
}.

print "Starting Landing Burn".
lock throttle to 0.1.
gear on.
rcs off.
unlock steering.
SET SHIP_RADAR_HEIGHT TO 10.

// PHASE 1: Point the right way!
PRINT "SETTING SAS".
sas on.
WAIT 0.0001.
SET SASMODE TO "RETROGRADE".
WAIT 3.
sas off.

// PHASE 2: Kill our horizontal velocity (surface speed)
PRINT "KILLING HORIZONTAL VELOCITY".
UNTIL SHIP:GROUNDSPEED < 25 {
	LOCK THROTTLE TO 1.
	WAIT 0.01.
}
LOCK THROTTLE TO 0.


// PHASE 3: Landing
PRINT "STARTING DESCENT LOGIC".
SET DESIREDVEL TO 200.
SET T TO 0.
LOCK THROTTLE TO T.

// Loop until we're two meters above the ground.
UNTIL ALT:RADAR < SHIP_RADAR_HEIGHT+6 {

	if( ALT:RADAR < 10 ) {
		SET DESIREDVEL TO 2.
	}
	else if( ALT:RADAR < 35 ) {
		SET DESIREDVEL TO 5.
	}
	else if( ALT:RADAR < 75 ) {
		SET DESIREDVEL TO 10.
    lock steering to up.
	}
	else if( ALT:RADAR < 200 ) {
		SET DESIREDVEL TO 25.
	}
	else if( ALT:RADAR < 500 ) {
		SET DESIREDVEL TO 50.
	}
	else if( ALT:RADAR < 750 ) {
		SET DESIREDVEL TO 100.
	}

	if( SHIP:VELOCITY:SURFACE:MAG > DESIREDVEL ) {
		SET T TO MIN(1, T + 0.01).
	}
	else {
		SET T TO MAX(0, T - 0.1).
	}

	// If we're going up, something isn't quite right -- make sure to kill the throttle.
	if(SHIP:VERTICALSPEED > 0) {
		SET T TO 0.
	}

	WAIT 0.001.
}

PRINT "ENGINE SHUTDOWN".
LOCK THROTTLE TO 0.
WAIT 3.
UNLOCK STEERING.
rcs on.
AG1 on.
lock throttle to 1.
brakes off.
sas off.
lock steering to up.
SET MYSTEER TO HEADING(90,45).
wait 5.
rcs off.
wait 5.
lock throttle to 0.
unlock throttle.
print "Handing Rocket Control over to Manual Control".
wait 1.
print "Vehicle Ready for Recovery".
print "---------------------------------------".
print "ARC Single Stage to Orbit Will now Exit".
SHUTDOWN.