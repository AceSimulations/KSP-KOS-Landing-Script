//Stage1 Booster Flight Profile Update
// Boostback Conditions:
// MUST be 1 if inclination is not equal to 90
set boostback to 0.     //0 = water    1 = land
//If boostback = 1 Inclination can not be 90

wait until ALT:RADAR > 500.
if boostback = 0 {  //land on droneship
  if ship:verticalspeed < -10 {
    RUNPATH("0:/VS2b.ks").  //run droneship software
  }
  else {
    print ship:mass.
    WAIT UNTIL ship:mass < 80.  //detect stage separation large change in mass
    wait 2. //wait for vehicle to clear interstage
    //Fuel Transfer
    print "Transfering Fuel".
    SET T1 to SHIP:PARTSDUBBED("1").  //bottom tank
    SET T2 to SHIP:PARTSDUBBED("2").  //2nd from bottom tank
    SET T3 to SHIP:PARTSDUBBED("3").  //3rd from bottom tank
    SET T4 to SHIP:PARTSDUBBED("4").  //3rd from top tank
    SET T5 to SHIP:PARTSDUBBED("5").  //2nd from top tank
    SET T6 to SHIP:PARTSDUBBED("6").  //top tank
    print "Fuel Transfer Start".
    wait .1.
    SET LF6 TO TRANSFERALL("LqdMethane", T6, T1).
    SET LF5 TO TRANSFERALL("LqdMethane", T5, T1).
    SET LF4 TO TRANSFERALL("LqdMethane", T4, T1).
    SET LF3 TO TRANSFERALL("LqdMethane", T3, T1).
    SET LF2 TO TRANSFERALL("LqdMethane", T2, T1).
    wait .1.
    print "Liguid Fuel Transfer Nominal".
    SET LF6:ACTIVE to TRUE.
    SET LF5:ACTIVE to TRUE.
    SET LF4:ACTIVE to TRUE.
    SET LF3:ACTIVE to TRUE.
    SET LF2:ACTIVE to TRUE.
    print "Liguid Fuel Transfer Complete".
    wait .1.
    SET OX6 TO TRANSFERALL("OXIDIZER", T6, T1).
    SET OX5 TO TRANSFERALL("OXIDIZER", T5, T1).
    SET OX4 TO TRANSFERALL("OXIDIZER", T4, T1).
    SET OX3 TO TRANSFERALL("OXIDIZER", T3, T1).
    SET OX2 TO TRANSFERALL("OXIDIZER", T2, T1).
    print "Oxidizer Fuel Transfer Nominal".
    wait .1.
    SET OX6:ACTIVE to TRUE.
    SET OX5:ACTIVE to TRUE.
    SET OX4:ACTIVE to TRUE.
    SET OX3:ACTIVE to TRUE.
    SET OX2:ACTIVE to TRUE.
    print "Oxidizer Fuel Transfer Complete".
    rcs off.
    sas off.
    unlock steering.
    wait until ship:verticalspeed < -10. 
    RUNPATH("0:/VS2b.ks").  //run droneship flight software
  }
}

else if boostback = 1 {
  if ship:verticalspeed < -10 {
    RUNPATH("0:/VS2a.ks").  //run RTLS flight software
  }
  else {
    print ship:mass.
    WAIT UNTIL ship:mass < 80.  //detect stage separation with large change in mass
    wait 2.
    //Fuel Transfer
    print "Transfering Fuel".
    SET T1 to SHIP:PARTSDUBBED("1").  //bottom tank
    SET T2 to SHIP:PARTSDUBBED("2").  //2nd from bottom tank
    SET T3 to SHIP:PARTSDUBBED("3").  //3rd from bottom tank
    SET T4 to SHIP:PARTSDUBBED("4").  //3rd from top tank
    SET T5 to SHIP:PARTSDUBBED("5").  //2nd from top tank
    SET T6 to SHIP:PARTSDUBBED("6").  //top tank
    print "Fuel Transfer Start".
    wait .1.
    SET LF6 TO TRANSFERALL("LqdMethane", T6, T1).
    SET LF5 TO TRANSFERALL("LqdMethane", T5, T1).
    SET LF4 TO TRANSFERALL("LqdMethane", T4, T1).
    SET LF3 TO TRANSFERALL("LqdMethane", T3, T1).
    SET LF2 TO TRANSFERALL("LqdMethane", T2, T1).
    wait .1.
    print "Liguid Fuel Transfer Nominal".
    SET LF6:ACTIVE to TRUE.
    SET LF5:ACTIVE to TRUE.
    SET LF4:ACTIVE to TRUE.
    SET LF3:ACTIVE to TRUE.
    SET LF2:ACTIVE to TRUE.
    print "Liguid Fuel Transfer Complete".
    wait .1.
    SET OX6 TO TRANSFERALL("OXIDIZER", T6, T1).
    SET OX5 TO TRANSFERALL("OXIDIZER", T5, T1).
    SET OX4 TO TRANSFERALL("OXIDIZER", T4, T1).
    SET OX3 TO TRANSFERALL("OXIDIZER", T3, T1).
    SET OX2 TO TRANSFERALL("OXIDIZER", T2, T1).
    print "Oxidizer Fuel Transfer Nominal".
    wait .1.
    SET OX6:ACTIVE to TRUE.
    SET OX5:ACTIVE to TRUE.
    SET OX4:ACTIVE to TRUE.
    SET OX3:ACTIVE to TRUE.
    SET OX2:ACTIVE to TRUE.
    print "Oxidizer Fuel Transfer Complete".

    rcs on. //provide control for boostback
    sas off.
    set targetGeo to LATLNG(28.6068,-80.5983).  //LZ1 position information
    lock targetPos to targetGeo:POSITION. //Vector to LZ1
    SET Vehicle_Status to "Status [ 2 ]".  //1=ascent 2=MECO/Stage Sep 3=Boostback 4=Entry 5=Approach 6=Landing Burn 7=Shutdown H=High Approach L=Low Approach 1EX=Entry Burn Part X
    print "Vehicle Status" at(0,22).
    print Vehicle_Status at(0,23).
    lock steering to srfretrograde.
    print "Change Active Vehicle To Me For Guidance".
    wait 3.
    lock lngoff to (targetGeo:lng - addons:tr:impactpos:lng). //Lng Error
    lock latoff to (targetGeo:lat - addons:tr:impactpos:lat). //Lat Error
    lock boostbackv to (addons:tr:impactpos:position - targetGeo:position). //boostback vector
    lock steering to -boostbackv. //invert so engines push to LZ1
    wait until vang(ship:facing:forevector,-boostbackv) < 5.  //wait until close to angle wanted
    AG6 on. //Keep outer engine on for moreee powerrrr

    //Boostback Burn
    lock throttle to .7.
    wait until lngoff >= -1.  //getting closer to target impact
    lock throttle to .8.
    AG6 off.  //Shutdown outer engine ring
    wait until lngoff >= -.02. //Have impact point hit LZ1
    lock throttle to 0.
    unlock all. //prevent errors and reset flight computer
    wait 2.
    rcs off.
    wait until ship:verticalspeed < -10.
    RUNPATH("0:/VS2a.ks").  //run RTLS flight software
  }
}