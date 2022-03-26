//Stage1 Booster Flight Profile Update

// Boostback Conditions:
// MUST be 1 if inclination is not equal to 90
// MUST be 0 for low TWR second stage

set boostback to 0.     //0 = water    1 = land
set sepAlt to 150000. //altitude apogee for stage separation

wait until ALT:RADAR > 1000.

if boostback = 0 {
  if ship:verticalspeed < -10 {
    AG7 on.
    rcs on.
    sas off.
    lock steering to up.
    WAIT UNTIL ALT:RADAR < 100000.
    wait 3.
    RUNPATH("0:/VS2b.ks").
  }
  else {
    rcs off.
    WAIT UNTIL ALT:RADAR > 70000.
    print "Transfering Fuel".
    SET header to SHIP:PARTSDUBBED("Header").
    SET central to SHIP:PARTSDUBBED("Central").
    SET lower to SHIP:PARTSDUBBED("Lower").
    SET base to SHIP:PARTSDUBBED("Base").
    print "Fuel Transfer Start".
    wait .1.
    SET LF1 TO TRANSFERALL("LqdMethane", header, central).
    SET LF2 TO TRANSFERALL("LqdMethane", central, lower).
    SET LF3 TO TRANSFERALL("LqdMethane", lower, base).
    wait .1.
    print "Liguid Fuel Transfer Nominal".
    SET LF1:ACTIVE to TRUE.
    SET LF2:ACTIVE to TRUE.
    SET LF3:ACTIVE to TRUE.
    print "Liguid Fuel Transfer Complete".
    wait .1.
    SET OX1 TO TRANSFERALL("OXIDIZER", header, central).
    SET OX2 TO TRANSFERALL("OXIDIZER", central, lower).
    SET OX3 TO TRANSFERALL("OXIDIZER", lower, base).
    print "Oxidizer Fuel Transfer Nominal".
    wait .1.
    SET OX1:ACTIVE to TRUE.
    SET OX2:ACTIVE to TRUE.
    SET OX3:ACTIVE to TRUE.
    print "Oxidizer Fuel Transfer Complete".
    AG7 on.
    rcs on.
    sas off.
    lock steering to up.
    wait until ALT:RADAR > 100000.
    wait 3.
    RUNPATH("0:/VS2b.ks").
  }
}

else if boostback = 1 {
  if ship:verticalspeed < -10 {
    WAIT UNTIL ALT:RADAR < 100000.
    wait 1.
    RUNPATH("0:/VS2a.ks").
  }
  else {
    wait until SHIP:APOAPSIS > sepAlt.
    wait until ALT:RADAR > 1000.
    set targetGeo to LATLNG(28.6068,-80.5983).  //land
    lock targetPos to targetGeo:POSITION.
    SET Vehicle_Status to "Status [ 2 ]".  //1=ascent 2=MECO/Stage Sep 3=Boostback 4=Entry 5=Approach 6=Landing Burn 7=Shutdown H=High Approach L=Low Approach 1EX=Entry Burn Part X
    print "Vehicle Status" at(0,22).
    print Vehicle_Status at(0,23).
    wait 5.
    sas off.
    lock steering to up.
    rcs on.
    wait 1.

    print "Transfering Fuel".
    SET header to SHIP:PARTSDUBBED("Header").
    SET central to SHIP:PARTSDUBBED("Central").
    SET lower to SHIP:PARTSDUBBED("Lower").
    SET base to SHIP:PARTSDUBBED("Base").
    print "Fuel Transfer Start".
    wait .1.
    SET LF1 TO TRANSFERALL("LqdMethane", header, central).
    SET LF2 TO TRANSFERALL("LqdMethane", central, lower).
    SET LF3 TO TRANSFERALL("LqdMethane", lower, base).
    wait .1.
    print "Liguid Fuel Transfer Nominal".
    SET LF1:ACTIVE to TRUE.
    SET LF2:ACTIVE to TRUE.
    SET LF3:ACTIVE to TRUE.
    print "Liguid Fuel Transfer Complete".
    wait .1.
    SET OX1 TO TRANSFERALL("OXIDIZER", header, central).
    SET OX2 TO TRANSFERALL("OXIDIZER", central, lower).
    SET OX3 TO TRANSFERALL("OXIDIZER", lower, base).
    print "Oxidizer Fuel Transfer Nominal".
    wait .1.
    SET OX1:ACTIVE to TRUE.
    SET OX2:ACTIVE to TRUE.
    SET OX3:ACTIVE to TRUE.
    print "Oxidizer Fuel Transfer Complete".

    SET WARP TO 0.
    print targetGeo.
    rcs on.
    sas off.
    wait .5.
    lock throttle to 0.
    wait 0.01.
    set SteeringManager:MAXSTOPPINGTIME to 2.5.
    set STEERINGMANAGER:PITCHTS to 1.
    set STEERINGMANAGER:YAWTS to 1.
    SET Vehicle_Status to "Status [ 3 ]".  //1=ascent 2=MECO/Stage Sep 3=Boostback 4=Entry 5=Approach 6=Landing Burn 7=Shutdown H=High Approach L=Low Approach 1EX=Entry Burn Part X
    print "Vehicle Status" at(0,22).
    print Vehicle_Status at(0,23).

    lock lngoff to (targetGeo:lng - addons:tr:impactpos:lng).
    lock latoff to (targetGeo:lat - addons:tr:impactpos:lat).
    lock boostbackv to (addons:tr:impactpos:position - targetGeo:position).
    lock steering to -boostbackv.

    SET WARP TO 0.
    sas off.
    wait 10.
    AG4 on.

    lock throttle to 1.
    wait until lngoff >= -.1.
    lock throttle to .5.
    AG4 off.
    wait until lngoff >= 0.
    lock throttle to 0.

    rcs off.
    lock targetPos to targetGeo:POSITION.
    RUNPATH("0:/VS2a.ks").
  }
}