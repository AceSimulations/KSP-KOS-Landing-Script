//Stage1 Booster Flight Profile Update
// Boostback Conditions:
// MUST be 1 if inclination is not equal to 90
set boostback to 0.     //0 = water    1 = land
//If 0 Inclination can not be 90

wait until ALT:RADAR > 500.
if boostback = 0 {
  if ship:verticalspeed < -10 {
    RUNPATH("0:/VS2b.ks").
  }
  else {
    print ship:mass.
    WAIT UNTIL ship:mass < 80.
    wait 2.
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
    rcs on.
    sas off.
    lock steering to up.
    wait until ALT:RADAR > 100000.
    RUNPATH("0:/VS2b.ks").
  }
}

else if boostback = 1 {
  if ship:verticalspeed < -10 {
    RUNPATH("0:/VS2a.ks").
  }
  else {
    print ship:mass.
    WAIT UNTIL ship:mass < 80.
    wait 2.
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
    rcs on.
    sas off.
    set targetGeo to LATLNG(28.6068,-80.5983).  //land
    lock targetPos to targetGeo:POSITION.
    SET Vehicle_Status to "Status [ 2 ]".  //1=ascent 2=MECO/Stage Sep 3=Boostback 4=Entry 5=Approach 6=Landing Burn 7=Shutdown H=High Approach L=Low Approach 1EX=Entry Burn Part X
    print "Vehicle Status" at(0,22).
    print Vehicle_Status at(0,23).
    lock steering to srfretrograde.
    print "Change Active Vehicle To Me For Guidance".
    wait 5.
    lock lngoff to (targetGeo:lng - addons:tr:impactpos:lng).
    lock latoff to (targetGeo:lat - addons:tr:impactpos:lat).
    lock boostbackv to (addons:tr:impactpos:position - targetGeo:position).
    lock steering to -boostbackv.
    wait 10.
    AG4 on.

    //Boostback Burn
    lock throttle to .7.
    wait until lngoff >= -1.
    lock throttle to .8.
    AG4 off.
    wait until lngoff >= 0.
    lock throttle to 0.
    unlock all.

    rcs off.
    wait until ship:verticalspeed < -10.
    RUNPATH("0:/VS2a.ks").
  }
}