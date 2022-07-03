//Stage 1 Booster Flight Profile Update
// Boostback Conditions:
// MUST be 1 if inclination is not equal to 90
wait 3.
set boostback to 1.     //0 = water    1 = land
set dirSelect to 3.     //0 = lng   1 = lat 2 = -lng   3 = -lat
//If boostback = 1 Inclination can not be 28

wait until ALT:RADAR > 500.
if boostback = 0 {  //land on droneship
  if ship:verticalspeed < -10 {
    RUNPATH("0:/boot/VS2b.ks").  //run droneship software
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
    SET T7 to SHIP:PARTSDUBBED("7").  //extra tank
    SET T8 to SHIP:PARTSDUBBED("7").  //extra tank 2
    print "Fuel Transfer Start".
    wait .1.
    SET LF8 TO TRANSFERALL("LqdMethane", T8, T1).
    SET LF7 TO TRANSFERALL("LqdMethane", T7, T1).
    SET LF6 TO TRANSFERALL("LqdMethane", T6, T1).
    SET LF5 TO TRANSFERALL("LqdMethane", T5, T1).
    SET LF4 TO TRANSFERALL("LqdMethane", T4, T1).
    SET LF3 TO TRANSFERALL("LqdMethane", T3, T1).
    SET LF2 TO TRANSFERALL("LqdMethane", T2, T1).
    wait .1.
    print "Liguid Fuel Transfer Nominal".
    SET LF8:ACTIVE to TRUE.
    SET LF7:ACTIVE to TRUE.
    SET LF6:ACTIVE to TRUE.
    SET LF5:ACTIVE to TRUE.
    SET LF4:ACTIVE to TRUE.
    SET LF3:ACTIVE to TRUE.
    SET LF2:ACTIVE to TRUE.
    print "Liguid Fuel Transfer Complete".
    wait .1.
    SET OX8 TO TRANSFERALL("OXIDIZER", T8, T1).
    SET OX7 TO TRANSFERALL("OXIDIZER", T7, T1).
    SET OX6 TO TRANSFERALL("OXIDIZER", T6, T1).
    SET OX5 TO TRANSFERALL("OXIDIZER", T5, T1).
    SET OX4 TO TRANSFERALL("OXIDIZER", T4, T1).
    SET OX3 TO TRANSFERALL("OXIDIZER", T3, T1).
    SET OX2 TO TRANSFERALL("OXIDIZER", T2, T1).
    print "Oxidizer Fuel Transfer Nominal".
    wait .1.
    SET OX8:ACTIVE to TRUE.
    SET OX7:ACTIVE to TRUE.
    SET OX6:ACTIVE to TRUE.
    SET OX5:ACTIVE to TRUE.
    SET OX4:ACTIVE to TRUE.
    SET OX3:ACTIVE to TRUE.
    SET OX2:ACTIVE to TRUE.
    print "Oxidizer Fuel Transfer Complete".
    rcs off.
    sas off.
    unlock steering.
    set core:bootfilename to "VS2b.ks".
    RUNPATH("0:/boot/VS2b.ks").  //run droneship flight software
  }
}

else if boostback = 1 {
  if ship:verticalspeed < -10 {
    RUNPATH("0:/boot/VS2a.ks").  //run RTLS flight software
  }
  else {
    print ship:mass.
    WAIT UNTIL ship:mass < 80.  //detect stage separation with large change in mass
    wait 2.
    rcs on. //provide control for boostback
    sas off.
    set targetGeo to LATLNG(28.6068,-80.5983).  //LZ1 position information
    lock targetPos to targetGeo:POSITION. //Vector to LZ1
    SET Vehicle_Status to "Status [ 2 ]".  //1=ascent 2=MECO/Stage Sep 3=Boostback 4=Entry 5=Approach 6=Landing Burn 7=Shutdown H=High Approach L=Low Approach 1EX=Entry Burn Part X
    print "Vehicle Status" at(0,22).
    print Vehicle_Status at(0,23).
    lock steering to srfretrograde.
    lock throttle to .1.
    print "Change Active Vehicle To Me For Guidance".
    wait 3.
    lock lngoff to (targetGeo:lng - addons:tr:impactpos:lng). //Lng Error
    lock latoff to (targetGeo:lat - addons:tr:impactpos:lat). //Lat Error
    lock boostbackv to (addons:tr:impactpos:position - targetGeo:position). //boostback vector
    LOCK STEERING TO LOOKDIRUP(ANGLEAXIS((-5),VCRS(-boostbackv,BODY:POSITION))*-boostbackv,FACING:TOPVECTOR). //invert so engines push to LZ1
    wait until vang(ship:facing:forevector,ANGLEAXIS((-5),VCRS(-boostbackv,BODY:POSITION))*-boostbackv) < 5.  //wait until close to angle wanted
    AG6 on. //Keep outer engine on for moreee powerrrr

    //Boostback Burn
    lock throttle to .7.
    wait 4.
    rcs off.
    if dirSelect = 0 {
      wait until lngoff >= -.5.  //getting closer to target impact lng
    } else if dirSelect = 1 {
      wait until latoff >= -.5.  //getting closer to target impact lat
    } else if dirSelect = 2 {
      wait until lngoff <= .5.  //getting closer to target impact -lng
    } else if dirSelect = 3 {
      wait until latoff <= .5.  //getting closer to target impact -lat
    }
    lock throttle to .8.
    AG6 off.  //Shutdown outer engine ring
    if dirSelect = 0 {
      wait until lngoff >=  -.02.  //Have impact point hit LZ1 lng
    } else if dirSelect = 1 {
      wait until latoff >=  -.02.  //Have impact point hit LZ1 lat
    } else if dirSelect = 2 {
      wait until lngoff <=  .02.  //Have impact point hit LZ1 -lng
    } else if dirSelect = 3 {
      wait until latoff <=  .02.  //Have impact point hit LZ1 -lat
    }
    lock throttle to 0.
    unlock all. //prevent errors and reset flight computer
    wait 2.
    rcs off.
    set core:bootfilename to "VS2a.ks".
    RUNPATH("0:/boot/VS2a.ks").  //run RTLS flight software
  }
}