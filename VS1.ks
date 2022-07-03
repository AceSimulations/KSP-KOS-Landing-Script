//LAST UPDATED: 7/3/2022
//This is a upgraded launch software with help from CLS and KSlib for use on Ace Rocket Co Vehicles
CLEARSCREEN.
/////////////////////////////////////////////////////////////////////////
////////////////////////////FLIGHT CONDITIONS////////////////////////////
/////////////////////////////////////////////////////////////////////////
// Default launch parameters
set targetapoapsis to 300000.		//highest point in orbit
set targetperiapsis to 300000.	//lowest point in orbit
set targetinclination to -90.		//TARGET ORBITAL INCLINATION IN DEGREES
//NOTE: For Droneship landing set inclination to 28
if targetinclination = 28 {
	set RTLS to false.	//This will trigger an DSL
} else {
	set RTLS to true.	//This will trigger a RTLS
}
set launchWindow to 20.	//Countdown starts at T-
// TWR configuration
set minLiftoffTWR to 1.5.	//Minimum liftoff TWR. -> TRIGGERS APORT IF NOT MET
set LiftoffTWR to 2.4.	//Liftoff TWR should be near 100% thrust
set maxAscentTWR to 4.	//Maximum TWR during ascent -> Throttle to maintain
set UpperAscentTWR to 0.8.	//S2 throttle to maintain once time to apoapsis is high enough
// Initiate settings
set launchLocation to ship:geoposition.	//used to calc downrange distance
set terminal:width to 50. 
set terminal:height to 50.
AG1 on.	//opens terminal
SET WARPMODE TO "PHYSICS".  //Allow warping
lock cdown to Time:seconds - launchtime.	//time till launch

/////////////////////////////////////////////////////////////////////////
////////////////////////////////FUNCTIONS////////////////////////////////
/////////////////////////////////////////////////////////////////////////

//List of active engines
Function Activeenginelist {
	Enginelist().
	global aelist is list().
	For e in elist {
		If e:ignition and e:allowshutdown {
			aelist:add(e).
		}
	}
}
Activeenginelist().

//Scroll print function
//Credit to /u/only_to_downvote / mileshatem for the original (and much more straightforward) scrollprint function that this is an adaptation of
Function scrollprint {
	Parameter nextprint.
	Parameter timeStamp.
	local maxlinestoprint is 33.	//Max number of lines in scrolling print list
	if timeStamp = true {
		if runmode = 0 {
			local t_minus is "T" + hud_missionTime(cdown) + " - ".
			printlist:add(t_minus + nextprint).
		} else {
			local t_plus is "T" + hud_missionTime(missiontime) + " - ".
			printlist:add(t_plus + nextprint).
		}
	} else {
		printlist:add(nextprint).
	}
	if printlist:length < maxlinestoprint {
		For printline in printlist {
			print printlist[printlist:length-1] at (0,(printlist:length-1)+listlinestart).
		}
	} else {
		printlist:remove(0).
		local currentline is listlinestart.
		until currentLine = 38 {
			For printline in printlist {
				Print "                                                 " at (0,currentLine).
				Print printline at (0,currentline).
				Set currentline to currentline+1.
			}
		}
	}
}

//Creates a list of all fuel tanks and the stage they are assocated with Then compares the associated stages to find the tanks(s) associated with the largest/current stage
Function FuelTank {	
	Parameter resourceName.
	local MFT is list(list(),list(),list()).
	global stagetanks is list().
	for tank in ship:parts {
		for res in tank:resources {
			if res:name = resourceName and res:amount > 1 and res:enabled = true {
				MFT[0]:add(tank).
				MFT[2]:add(tank).
			}
		}
	}
	for p in MFT[0] {
		MFT[1]:add(p:stage).
	}
	 Until MFT[1]:length = 1 {
		if MFT[1][0] <= MFT [1][1] {
			MFT[1]:remove(0).
			MFT[0]:remove(0).
		} else if MFT[1][0] >= MFT[1][1] {
			MFT[1]:remove(1).
			MFT[0]:remove(1).
		}
	}
	stagetanks:add(MFT[0][0]).
	for p in MFT[2] {
		if p:uid = stagetanks[0]:uid {
		} else {
			if p:stage = stagetanks[0]:stage {
				stagetanks:add(p).
			}
		}
	}
}
Function FuelTankUpper {	
	Parameter resourceName.
	local MFT is list(list(),list(),list()).
	global stagetanks is list().
	for tank in ship:parts {
		for res in tank:resources {
			if res:name = resourceName and res:amount > 1 and res:enabled = true {
				MFT[0]:add(tank).
				MFT[1]:add(res:amount).
				MFT[2]:add(tank).
			}
		}
	}
	Until MFT[1]:length = 1 {
		if MFT[1][0] <= MFT [1][1] {
			MFT[1]:remove(0).
			MFT[0]:remove(0).
		} else if MFT[1][0] > MFT[1][1] {
			MFT[1]:remove(1).
			MFT[0]:remove(1).
		}
	}
	stagetanks:add(MFT[0][0]).
	for p in MFT[2] {
		if p:uid = stagetanks[0]:uid {
		} else {
			if p:stage = stagetanks[0]:stage {
				stagetanks:add(p).
			}
		}
	}
}

//Remaining dV of current stage
Function stageDV {
	local plist is aelist.
	local fuelmass is FuelRemaining(stagetanks,ResourceOne)*ResourceOneMass + FuelRemaining(stagetanks,ResourceTwo)*ResourceTwoMass.
	local shipMass is ship:mass.
	// effective ISP
	local mDotTotal is 0.
	local thrustTotal is 0.
	local averageIsp is 0.
	for e in plist {
		local thrust is e:thrust.
		if thrust = 0 {
			set thrust to e:possiblethrust.
		} 
		set thrustTotal to thrustTotal + thrust.
		if e:isp = 0 { 
			set mDotTotal to mDotTotal + thrust / max(1,e:ispat(ship:body:atm:altitudepressure(ship:altitude))).
		} else {
			set mDotTotal to mDotTotal + thrust / e:isp.
		}
	}
	if not mDotTotal = 0 {
		set averageIsp to thrustTotal/mDotTotal.
	}
	return (averageIsp*constant:g0*ln(shipMass / (shipMass-fuelmass)))-1.
}

//Remaining burn time
Function remainingBurn {
	local fuelRemainingVar is FuelRemaining(stagetanks,ResourceOne) + FuelRemaining(stagetanks,ResourceTwo).
	local fuelFlow is 0.01.
	local engList is aelist:copy().
	For e in aelist {
		if e:fuelflow = 0 {
			set fuelFlow to fuelFlow+e:maxfuelflow.
		} else {
			set fuelFlow to fuelFlow+e:fuelflow.
		}
	}
	return fuelRemainingVar/fuelFlow.
}

//dV required to circularise at current apoapsis
Function circulariseDV_Apoapsis {
	local v1 is (ship:body:mu * (2/(ship:apoapsis + ship:body:radius) - 2/(ship:apoapsis + ship:periapsis + 2*ship:body:radius)))^0.5.
	local v2 is (ship:body:mu * (2/(ship:apoapsis + ship:body:radius) - 2/(2*ship:apoapsis + 2*ship:body:radius)))^0.5.
	return ABS(v2-v1).
}

//dV required to circularise at current Periapsis
Function circulariseDV_Periapsis {
	local v1 is (ship:body:mu * (2/(ship:periapsis + ship:body:radius) - 2/(ship:apoapsis + ship:periapsis + 2*ship:body:radius)))^0.5.
	local v2 is (ship:body:mu * (2/(ship:periapsis + ship:body:radius) - 2/(2*ship:periapsis + 2*ship:body:radius)))^0.5.
	return v2-v1.
}

//dV required to circularise at a periapsis of the target orbit
Function circulariseDV_TargetPeriapsis {
	Parameter targetApo is 250000.
	Parameter targetPeri is 250000.
	local v1 is (ship:body:mu * (2/(targetPeri + ship:body:radius) - 2/(ship:apoapsis + targetPeri + 2*ship:body:radius)))^0.5.
	local v2 is (ship:body:mu * (2/(targetPeri + ship:body:radius) - 2/(targetApo + targetPeri + 2*ship:body:radius)))^0.5.
	return ABS(v2-v1).
}

//dV required at Apo to bring Peri to a target orbit
Function BurnApoapsis_TargetPeriapsis {
	Parameter targetOrbit is 250000.
	local v1 is (ship:body:mu * (2/(ship:apoapsis + ship:body:radius) - 2/(ship:apoapsis + ship:periapsis + 2*ship:body:radius)))^0.5.
	local v2 is (ship:body:mu * (2/(ship:apoapsis + ship:body:radius) - 2/(targetOrbit+ship:apoapsis + 2*ship:body:radius)))^0.5.
	return ABS(v2-v1).
}

//dV required at peri to bring apo to a target orbit
Function BurnPeriapsis_TargetApoapsis {
	Parameter targetOrbit is 250000.
	local v1 is (ship:body:mu * (2/(ship:periapsis + ship:body:radius) - 2/(ship:apoapsis + ship:periapsis + 2*ship:body:radius)))^0.5.
	local v2 is (ship:body:mu * (2/(ship:periapsis + ship:body:radius) - 2/(targetOrbit+ship:periapsis + 2*ship:body:radius)))^0.5.
	return v2-v1.
}

//half of burn time to find when to start burn
Function nodeBurnStart {
	Parameter MnVnode.
	local dV is MnVnode:deltav:mag/2.
	local f is ship:availablethrust.
	local m is ship:mass.
	local e is constant:e.
	local g is constant:g0.
	// effective ISP
	local p is 0.
	for e in aelist {
		set p to p + e:availablethrust / ship:availablethrust * e:vacuumisp.
	}	
	return g*m*p*(1-e^((-1*dV)/(g*p)))/f.
}

//time of day in hh:mm:ss format aka really not needed but looks cool
Function t_o_d {
	parameter time.
	local hoursPerDay is round(body:rotationperiod/3600).
	local dd is floor(time/(hoursPerDay*3600)).  
	local hh is floor((time-hoursPerDay*3600*dd)/3600).  
	local mm is floor((time-3600*hh-hoursPerDay*3600*dd)/60).  
	local ss is round(time) - mm*60 -   hh*3600 - hoursPerDay*3600*dd. 
	if ss = 60 {
		set ss to 0.
		set mm to mm+1.
	}
	if ss < 10 and mm > 10 {
		return hh + ":" + mm + ":0" + ss.
	}
	else if ss > 10 and mm < 10 {
		return hh + ":0" + mm + ":" + ss.
	}
	else if ss < 10 and mm < 10 {
		return hh + ":0" + mm + ":0" + ss.
	}
	else {
		return hh + ":" + mm + ":" + ss.
	}	
}

//mission time to mm:ss format
function hud_missionTime {
	parameter mission_time.
	local mm is floor(Abs(mission_time)/60).
	local ss is round(Abs(mission_time))-(mm*60).
	local t is "-".
	If mission_time < 0 {
		set t to "-".
	} else {
		set t to "+".
	}
	if ss < 10 {
		set ss to "0" + ss.
	}
	if ss = 60 {
		set mm to mm+1.
		set ss to "00".
	}
	if mm < 10 {
		set mm to "0" + mm.
	}
	
	return t + mm + ":" + ss.
}

//detect maxQ occurs
Function maxQ {
	parameter dynamicPressure.
	if dynamicPressure = 0 {
		global dynamicPressure is ship:Q.
	}
	if time:Seconds > dynamicPressureTime {
		if ship:Q < dynamicPressure {
			scrollPrint("Max Q",true).
			set passedMaxQ to true.
		} else {
			global dynamicPressure is ship:Q.
			global dynamicPressureTime is time:seconds+0.5.
		}
	}
}
	
//Periodic readouts for vehicle speed, altitude and downrange distance
Function eventLog {
	If missiontime >= logTime {
		//Downrange calculations
		local v1 is ship:geoposition:position - ship:body:position.
		local v2 is launchLocation:position - ship:body:position.
		local downRangeDistance is vang(v1,v2) * constant:degtorad * ship:body:radius.
		scrollPrint("Speed: "+FLOOR(Ship:AIRSPEED*3.6) + "km/h", true).
		scrollPrint("          Altitude: "+ROUND(ship:altitude/1000,2)+"km",false).
		scrollPrint("          Downrange: "+ROUND(downRangeDistance/1000,2)+"km",false).
		Set logTime to logTime + 60.
	}
}

//Countdown 
Function countdown {
	Parameter tminus.
	Parameter cdown.
	local cdlist is list(19,17,15,13,11,9,8,7,5,4).
	if cdlist[cdownreadout] = tminus and tminus > 3 {
		if ABS(cdown) <= tminus {
			scrollPrint("T" + hud_missionTime(cdown),false).
			set cdownreadout to min(cdownreadout+1,9).
			global tminus is tminus-1.
		}
	} 
}

//Data to be displayed on the terminal HUD.
Function AscentHUD {
	local hud_met is "Mission Elapsed Time: " + "T" + hud_missionTime(missiontime) + " (" + runmode + ") ".
	local hud_staging is "-------".
	local hud_apo is "Apo: " + padding(floor(ship:apoapsis/1000,2),1,2,false) + "km ".
	local hud_apo_eta is "eta: " + padding(round(eta:apoapsis,1),3,1,false) + "s    ".
	local hud_peri is "Per: " + padding(floor(ship:periapsis/1000,2),1,2,false) + "km ".
	local hud_peri_eta is "eta: " + padding(round(eta:periapsis,1),3,1,false) + "s    ".
	local hud_ecc is "Ecc: " + padding(max(Round(ship:orbit:eccentricity,4),0.0001),1,4,false).
	local hud_inc is "Inc: " + padding(Round(ship:orbit:inclination,5),1,5,false) + "°".
	local hud_dV is " dV: ------- ".
	local hud_dV_req is "Req: " + padding(Round(circulariseDV_Apoapsis()),2,0,false) + "m/s ".
	local hud_pitch is "Pitch: " + padding(Round(trajectorypitch,1),2,1,false) + "° ".
	local hud_head is "Head:  " + padding(Round(launchazimuth,1),2,1,false) + "°".
	local hud_fuel is "Fuel:  ----- ".
	local hud_twr is "TWR:   " + padding(Round(max(twr(),0),2),1,2,false).
	if tminus < 10 or runmode > 0 {
		set hud_dV to " dV: " + padding(Round(StageDV()),2,0,false) + "m/s ".
		set hud_fuel to "Fuel:  " + padding(min(999,Round(remainingburn())),3,0,false) + "s ".
	}
	if eta:apoapsis > 998 {
		set hud_apo_eta to "eta: " + padding(floor(eta:apoapsis/60),3,0,false) + "m    ".
	}
	if eta:periapsis > 998 {
		set hud_peri_eta to "eta: " + padding(floor(eta:periapsis/60),3,0,false) + "m    ".
	}
	If staginginprogress or ImpendingStaging {
		set hud_staging to "Staging".
	} 
	if LEO = true {
		if threeBurn = true {
			set hud_dV_req to "Req: " + padding(Round(BurnApoapsis_TargetPeriapsis(targetapoapsis)+ABS(circulariseDV_TargetPeriapsis(targetapoapsis,targetperiapsis))),2,0,false) + "m/s ".
		} else {
			set hud_dV_req to "Req: " + padding(Round(ABS(circulariseDV_Periapsis)),2,0,false) + "m/s ".
		}
	}
	if ship:apoapsis < ship:body:atm:height {
		set hud_dV_req to "Req: ------- ".
	}
	if runmode > 2 {
		set hud_pitch to "Pitch: " + padding(Round(90 - vectorangle(ship:up:forevector,ship:facing:forevector),1),2,1,false) + "° ".
		set hud_head to "Head:  " + padding(Round(heading_for_vector(ship:facing:forevector),1),2,1,false) + "°".
	}
	local hud_printlist is list(hud_met,hud_staging,hud_apo,hud_apo_eta,hud_peri,hud_peri_eta,hud_ecc,hud_inc,hud_dV,hud_dV_req,hud_pitch,hud_head,hud_fuel,hud_twr).
	local hud_printlocX is list(00,23,01,01,01,01,19,19,19,19,35,35,35,35).
	local hud_printlocY is list(04,40,41,42,43,44,41,42,43,44,41,42,43,44).
	local printLine is 0.
	until printLine = hud_printlist:length {
  print hud_printlist[printLine] at (hud_printlocx[printLine],hud_printlocy[printLine]).
	set printLine to printLine+1.
	}
}

//compass heading for specified vector -> Credit to /u/Dunbaratu for this function
function heading_for_vector {
	parameter vect.
	local east is vcrs(ship:up:vector, ship:north:vector)().
	local x is vdot(ship:north:vector,vect).
	local y is vdot(east,vect).
	local compass is arctan2(y,x).
	if compass < 0 { 
		return 360 + compass.
	} else {
		return compass.
	}	
}

//Calculates pitch for ascent -> Credit to TheGreatFez for this function.
function PitchProgram_Sqrt {
	parameter stageNumber is 1.
	parameter baseApogee is 0.
	local turnend is body:atm:height*1.15.
	local currentApogee is (ship:apoapsis-BaseApogee)+480.
	local pitch_ang is 90 - max(5,min(90,85*sqrt(currentApogee/turnend))).
	local maxQsteer is max(0,15-ship:q*15).
	local pitch_max is (90 - vectorangle(ship:up:forevector,Ship:srfprograde:forevector))+maxQsteer.
	local pitch_min is (90 - vectorangle(ship:up:forevector,Ship:srfprograde:forevector))-maxQsteer.
	local pitchOutput is max(min(pitch_ang,pitch_max),pitch_min).
	return pitchOutput.
}

//Fine tunes inclination
Function incTune {
	Parameter desiredInc.
	local output is 0.
	local inc is ship:orbit:inclination.
	if desiredInc < 0 {
		if inc < abs(desiredInc) {
			set output to heading_for_vector(ship:prograde:vector)+(sqrt(max(abs(desiredInc)-inc,0))*4).
		} else if inc >= abs(desiredInc) {
			set output to heading_for_vector(ship:prograde:vector)-(sqrt(max(abs(desiredInc)-inc,0))*4).
		}
	} else {	
		if inc < desiredInc {
			set output to heading_for_vector(ship:prograde:vector)-(sqrt(max(abs(desiredInc)-inc,0))*4).
		} else {
			set output to heading_for_vector(ship:prograde:vector)+(sqrt(max(abs(desiredInc)-inc,0))*4).
		}
	}
	if output < 0 { 
		return 360 + output.
	} else {
		return output.
	}	
}

//Checks if a resource is above a specified threshold -> used for electric aport triggers
Function resourceCheck {
	Parameter resourceName.
	Parameter threshold.
	For res in ship:resources {
		If res:name = resourceName {
			If (res:amount/res:capacity) <= threshold {
				return false.
			} else {
				return true.
			}
		}
	}
}

//fuel capacity of a given partlist
Function FuelRemaining {
	Parameter plist.
	Parameter resourceName.
	local r is 0.
	For tank in plist {
		For res in tank:resources {
			if res:name = resourceName and res:enabled = true {
				set r to (r + res:amount).
			}
		}
	}
	return r.
}

//main fuel 
Function PrimaryFuel {
	if runmode > 0 {
		Activeenginelist().
		global engine is aelist[0].
	} else {
		list engines in elist.
		for p in elist {
			if p:stage = stage:number-1 {
				global engine is p.
			}
		}
	}
	//First Resource
	local res1 is engine:consumedResources:values[0]:tostring.
	local res1 is res1:substring(17,res1:length-17).
	global ResourceOne is res1:remove(res1:length-1,1).
	//Second Resource
	local res2 is engine:consumedResources:values[1]:tostring.
	local res2 is res2:substring(17,res2:length-17).
	global ResourceTwo is res2:remove(res2:length-1,1).
}

//mass of main fuel
Function PrimaryFuelMass {
	global resourceMass is list().
	global resourceName is list().
	For res in ship:resources {
		resourceName:add(res:name).
		resourceMass:add(res:density).
	}
	Global ResourceOneMass is resourceMass[resourceName:find(ResourceOne)].
	Global ResourceTwoMass is resourceMass[resourceName:find(ResourceTwo)].
}

//twr
Function twr {
	local throt is min(throttle,1).
	local g is (constant:g*body:mass)/(body:radius+ship:altitude)^2.
	local engThrust is PartlistAvailableThrust(aelist)+0.01.
	return (throt*engThrust)/(ship:mass*g).
}

//throttle required to achieve a given TWR
Function twrthrottle {
	parameter targetTWR.
	local g is (constant:g*body:mass)/(body:radius+ship:altitude)^2.
	local engThrust is ship:availablethrust+0.1.
	global twrThrot is (ship:mass*g)/engThrust*targetTWR.
	return Max(0.01,Min(1,twrThrot)).
}

//list of engines
Function EngineList {
	global elist is list().
	For P in ship:parts {
		If P:modules:join(","):contains("ModuleEngine") {
			If not P:hasmodule("moduledecouple") {
				elist:add(p).
			}
		}
	}
}

//total available thrust of a partlist
Function PartlistAvailableThrust {
	Parameter plist.
	local thrust is 0.01.
	For e in plist {
		set thrust to thrust + e:availablethrust.
	}
	return thrust.
}

Function LAZcalc_init {
    Parameter desiredAlt.		 	//Altitude of desired target orbit (in *meters*)
    Parameter desiredInc. 			//Inclination of desired target orbit
    local autoNodeEpsilon is 10. 		// How many m/s north or south will cause a north/south switch
    local launchLatitude is ship:latitude.
    local data is list().  			// A list is used to store information used by LAZcalc
    //Determines whether we're trying to launch from the ascending or descending node
    local launchNode is "Ascending".
    if desiredInc < 0 {
	set launchNode to "Descending".
        set desiredInc to abs(desiredInc).       //We'll make it positive for now and convert to southerly heading later
    }
    //Does all the one time calculations and stores them in a list to help reduce the overhead or continuously updating
    local equatorialVel is (2 * constant():pi * body:radius) / body:rotationPeriod.
    local targetOrbVel is sqrt(body:mu/ (body:radius + desiredAlt)).
    data:add(desiredInc).       //[0]
    data:add(launchLatitude).   //[1]
    data:add(equatorialVel).    //[2]
    data:add(targetOrbVel).     //[3]
    data:add(launchNode).       //[4]
    data:add(autoNodeEpsilon).  //[5]
    return data.
}

Function LAZcalc {
    Parameter data.		//list created by LAZcalc_init
    local inertialAzimuth is arcsin(max(min(cos(data[0]) / cos(ship:latitude), 1), -1)).
    local VXRot is data[3] * sin(inertialazimuth) - data[2] * cos(data[1]).
    local VYRot is data[3] * cos(inertialazimuth).
    //This clamps the result to values between 0 and 360.
    local azimuth is mod(arctan2(VXRot, VYRot) + 360, 360).
    local NorthComponent is vdot(ship:velocity:orbit, ship:north:vector).
    if NorthComponent > data[5] {
        set data[4] TO "Ascending".
    } else if NorthComponent < -data[5] {
        set data[4] to "Descending".
    }    
    //Returns azimuth based on the ascending node
    if data[4] = "Ascending" {
        return azimuth.
    } else if data[4] = "Descending" {
        if azimuth <= 90 {
            return 180 - azimuth.   
        } else if azimuth >= 270 {
            return 540 - azimuth.
        } else {
			return azimuth.
		}
    }
}

//current compass heading 
function heading_for {
  local pointing is ship:facing:forevector.
  local east is vcrs(ship:up:vector, ship:north:vector)().
  local trig_x is vdot(ship:north:vector, pointing).
  local trig_y is vdot(east, pointing).
  local result is arctan2(trig_y, trig_x).
  if result < 0 { 
    return 360 + result.
  } else {
    return result.
  }
}

function padding {
	Parameter num.               			// number to be formatted
	Parameter leadingLength.                // minimum digits to the left of the decimal
	Parameter trailingLength.               // digits to the right of the decimal
	Parameter positiveLeadingSpace is true. // whether to prepend a single space to the output
	Parameter roundType is 0.               // 0 for normal rounding, 1 for floor, 2 for ceiling
	Local returnString is "".
	If roundType = 0 {
		set returnString to ABS(round(num,trailingLength)):tostring.
	} else if roundType = 1 {
		set returnString to ABS(adv_floor(num,trailingLength)):tostring.
	} else {
		set returnString to ABS(adv_ceiling(num,trailingLength)):tostring.
	}
	if num < 0 {
		set leadingLength to leadingLength-1.
	}
	If trailingLength > 0 {
		If not returnString:CONTAINS(".") {
			set returnString to returnString + ".0".
		}
		until returnString:split(".")[1]:length >= trailingLength { set returnString to returnString + "0". }
		until returnString:split(".")[0]:length >= leadingLength { set returnString to "0" + returnString. }
	} else {
		until returnString:length >= leadingLength { set returnString to "0" + returnString. }
	}
	If num < 0 {
		return "-" + returnString.
	} else {
		If positiveLeadingSpace {
			return " " + returnString.
		} else {
			return returnString.
		}
	}
}

/////////////////////////////////////////////////////////////////////////
////////////////////////////////VARIABLES////////////////////////////////
/////////////////////////////////////////////////////////////////////////
//Orbit Variables
set atmAlt to ship:body:atm:height+1000.	//Atmosphere Altitude
If targetapoapsis < atmAlt*1.42857143 {
	set LEO to true.
	lock orbitData to ship:periapsis.
} else {
	set LEO to false.
	lock orbitData to ship:apoapsis.
}	
//Initial launch data
set lngoff to 0.	//Init for Difference between predicted impact and target
set latoff to 0.	//Nobody cares about lat but I will use it anyway
set boostbackv to 0.	//init for Parallel vector to vector between impact and target location
set launchazimuth to LAZcalc(LAZcalc_init(targetapoapsis,targetinclination)).	//heading to hit desired inclination
set trajectorypitch to 90.	//pitch of vehicle (start vertical)
set launchtime to Time:seconds + launchWindow.	//T-0 based on current time plus the countdown time
if RTLS = true {	//Launch Site Landing
	lock steering to heading(launchazimuth,trajectorypitch,0).	//Main steering command
} else {	//Droneship Landing
	set target to "DroneShip".
	wait .1.
	lock DronePos to Target:GEOPOSITION.	//Geo LAT, LNG coordinates
	lock targetGeo TO LATLNG((DronePos:LAT),(DronePos:LNG + 1.15)).	//Target Adjustment
	lock steering to up.
}
//Staging variables
set ImpendingStaging to false.																//True when rocket is about to stage
set ImpendingStagingTime to 0.																//time at imminent staging
set ImpendingStagingPitch to 0.																//pitch at imminent staging
set staginginprogress to false.																//True when rocket is staging
set stagingComplete to false.																	//True when staging has succesfully occured
set stagingStartTime to Time:seconds+100000.									//staging start time
set stagingEndTime to Time:seconds+100000.										//staging end time
set stagingApoapsisETA to 1000.																//eta:apoapsis at staging - used to determine when upper stages can throttle down
//Loop variables 
set launchcomplete to false.																	//Master script trigger (when true script shutsdown)
set runmode to 0.																							//Flight mode
set cdownreadout to 0.																				//Countdown function
set tminus to 20.																							//Countdown timer
set launchThrottle to 1.																			//liftoff throttle for TWR as configured above
set gravityTurnApogee to 0.																		//Ship apoapsis at gravity turn start
set throttletime to 0.																				//Time of engine throttling -> Used for gradual throttling.
set currentthrottle to 0.																			//Initial throttle during engine throttle up or down
set currentThrottle2 to 0.																		//Second iteration of current throttle for apopsis fine tuning.
set ApoETAcheck to false.																			//Vehicle time to apoapsis 
set throttleCheck to false.																		//upper stage can throttle down.	
set approachingApo to false.																	//Ship apopsis is getting close to the target to begin throttling down to tune apoapsis
set threeBurn to false.																				//3 burns is most efficicent to achieve target orbit
set ascentComplete to false.																	//Monitor multiple data streams to determine best time to end ascent
set ascentCompleteTime to time:seconds+100000.								//Time when ascent is completed
set insufficientDV to false.																	//not enough DV to complete ascent 
// Ship information / Variables
set currentstagenum to 1.																			//Current stage number
set numparts to Ship:parts:length.														//Number of parts -> if decrease unexpectedly triggers abort
set PayloadProtection to false.																//if fairings are currently attached
// Manuever node / burn variables
set burnStartTime to Time:seconds+100000.											//Time at which manuever burn should start. 
set burnStarted to false.																			//If burn has started
set burnDeltaV to 0.																					//initially calculated burn dV -> used to determine when burn should end
//HUD Initialise
set printlist to List(). set listlinestart to 6.							//Scrolling print configuration
//Variables used to track MaxQ and provide regular speed, distance & alitude updates (Below)
set logtime to 60. 
set dynamicPressure to 0. 
set dynamicPressureTime to 0. 
set passedMaxQ to false.	

/////////////////////////////////////////////////////////////////////////
//////////////////////////////////INIT///////////////////////////////////
/////////////////////////////////////////////////////////////////////////

Print "Launch Sequence Initialised" at (0,0).
Print "Target Launch Time: NET " + T_O_D(launchtime) at (0,1).
Print "Target Parking Orbit: " + Ceiling(targetapoapsis/1000,2) + "km x " + Ceiling(targetperiapsis/1000,2) + "km" at (0,2).
Print "Target Orbit Inclination: " + Ceiling(targetinclination,2) + "°" at (0,3).
Print "----------------------------------------------------" at (0,40).

//Main Flight Loop
Until launchcomplete {
/////////////////////////////////////////////////////////////////////////
////////////////////////////////COUNTDOWN////////////////////////////////
/////////////////////////////////////////////////////////////////////////
	//Initiate looping functions
	AscentHUD().	//Initiates the HUD information at the bottom of the terminal.
	//Countdown function handles the countdown seconds below are pre-launch checks
	If runmode = 0 {
		Countdown(tminus,cdown).					//Displays countdown on the terminal
		
		if cdown < -20 {
			print "T" + hud_missionTime(cdown) + launchNode + "   " at (0,(printlist:length)+listlinestart).	//Display a countdown
		} else if tminus = 20 {
			sas off.
			rcs off.
			scrollprint("Startup",true).
			set tminus to tminus-1.
		}
	
		//Hold launch if vehicle has < 40% electric charge
		If cdown >= -18 and tminus = 18 {
			If Resourcecheck("Electriccharge",0.4) = false {					//checks if resource is above a threshold
				scrollprint("Insufficient Power",false).
				set runmode to -13.
			} else {
				scrollprint(Ship:name + " is on Internal Power",true).
			}
			set tminus to tminus-1.
		}
		
		//Changes mode configuration
		If cdown >= -16 and tminus = 16 and RTLS = true {		
			scrollprint("Launch Mode RTLS Configured",true).
			set tminus to tminus-1.
		} else if cdown >= -16 and tminus = 16 and RTLS = false {		
			scrollprint("Launch Mode DSL Configured",true).
			set tminus to tminus-1.
		}
		
		//Staging checks
		If cdown >= -14 and tminus = 14 {
			scrollprint("Staging Checks Complete",true).
			set tminus to tminus-1.
		}
		
		//Determines main fuel tank and calculates its fuel capacity -> Holds launch if this cant be determined. 
		If cdown >= -12 and tminus = 12 {
			PrimaryFuel(). PrimaryFuelMass(). fueltank(ResourceOne).
			If FuelRemaining(stagetanks,ResourceOne) = 0 {
				scrollprint("MFT Detect Issue",false).
				set runmode to -13.
			}
			scrollprint("Pressurization Checks Complete",true).
			set tminus to tminus-1.
		}
		
		//Detect fairing configuration based on parts assigned to action group 7 -> Holds launch if there are no parts in action group 7
		If cdown >= -10 and tminus = 10 {
			If Ship:partsingroup("AG7"):length > 0 {
				scrollprint("Fairings Configured For Launch",true).
				set PayloadProtection to true.
			} else {
				scrollprint("Fairing Checks Complete",true).
				scrollprint("Fairing Advisory",false).
				set runmode to -13.
							
			}
			set tminus to tminus-1.
		}
		
		//abort procedures
		If cdown >= -6 and tminus = 6 {
			scrollprint("Abort Systems Configured For Launch",true).
			AG4 on.  //outer 1 engine ignition
			AG5 on.  //inner 2 engine iginition
			AG6 on.  //outer engine iginition
			set tminus to tminus-1.
		}
		
		//main engine throttle up during countdown
		If cdown >= -3 and tminus = 3 {
			Activeenginelist().
			scrollprint("Ignition",true).
			set throttletime to Time:seconds.
			set liftoffThrottle to TWRthrottle(LiftoffTWR).
			lock throttle to min(liftoffThrottle,liftoffThrottle*(Time:seconds-throttletime)/2).
			set tminus to tminus-1.
		}
		
		//Checks if engines are producing thrust -> aborts if not.
		If cdown >= -2 and tminus = 2 {
			if ship:availablethrust > 0.1 {
				scrollprint("T-00:02 - Thrust Verified",false).
			} else {
				lock throttle to 0.
				scrollprint("Launch Aborted",true).
				scrollprint("Insufficient Thrust",false).
				set launchcomplete to true.
			}
			set tminus to tminus-1.
		}	
		
		//Main engines reach lift-off thrust
		If cdown >= -1 and tminus = 1 {
			scrollPrint("T" + hud_missionTime(cdown),false).
			RemainingBurn().
			set tminus to tminus-1.
		}
		
		//Checks vehicle TWR -> abort if its below TWR configuration
		If cdown >= 0 and tminus = 0 and throttle >= TWRthrottle(LiftoffTWR) {
			If TWR() < minLiftoffTWR {
				lock throttle to 0.
				scrollprint("Launch Aborted",true).
				scrollprint("Insufficient Thrust",false).
				set launchcomplete to true.
			} else {
				Toggle ag8.	//Release Clamps
				set numparts to Ship:parts:length.
				scrollprint("Liftoff (" + T_O_D(time:seconds) + ")",false).
				set launchThrottle to TWRthrottle(LiftoffTWR).		//Records the throttle needed to achieve the launch TWR. Used to throttle engines during ascent.
				lock throttle to launchThrottle.
				set runmode to 1.
				if RTLS = false {	//Configure steering for droneship
					lock lngoff to (targetGeo:lng - addons:tr:impactpos:lng).   //Difference between predicted impact and target
					lock latoff to (targetGeo:lat - addons:tr:impactpos:lat).   //Nobody cares about lat but I will use it anyway
					lock boostbackv to (addons:tr:impactpos:position - targetGeo:position). //Parallel vector to vector between impact and target location
					lock steering to LOOKDIRUP(ANGLEAXIS((trajectorypitch * -1),VCRS(-boostbackv,BODY:POSITION))*-boostbackv,FACING:TOPVECTOR).	//Master steering command
				}
			}
		}
	}

/////////////////////////////////////////////////////////////////////////
//////////////////////////////////ASCENT/////////////////////////////////
/////////////////////////////////////////////////////////////////////////
	
	If runmode = 1 {			//Initial ascent Calculates when to start the gravity turn
		//Ship will gradually pitch to 5 degrees while it builds vertical speed
		set trajectorypitch to 90-(5/(100/ship:verticalspeed)).
		
		//Start of gravity turn - gravityTurnVelocity set at t-0
		if ship:verticalspeed > 100 {
			set runmode to 2.
			unlock cdown.
			set 0 to 0 + (launchazimuth - heading_for_vector(vcrs(ship:up:vector, ship:north:vector)())).
			scrollprint("Starting Ascent Trajectory",true).
			set gravityTurnApogee to ship:apoapsis.
		}
	}

	If runmode = 2 and not abort {		//Ascent trajectory program until reach desired apoapsis	
		if passedMaxQ = false { 
			maxQ(dynamicPressure).	//detect MaxQ
		}
		Eventlog().										//Initiates mission log readouts in the terminal

		//Azimuth calculation
		if abs(targetinclination) > 0.1 and abs(targetinclination) < 180 and ship:orbit:inclination > (abs(targetinclination) - 0.2) {
			set launchazimuth to incTune(targetinclination).
		} else {
			set launchazimuth to LAZcalc(LAZcalc_init(targetapoapsis,targetinclination)).
		}
		
		//Pitch calculation
		set trajectorypitch to PitchProgram_Sqrt(currentstagenum,gravityTurnApogee).
		
		//Staging Pitch control
		If ImpendingStaging {
			local pDiff is abs((90 - vectorangle(ship:up:forevector,Ship:srfprograde:forevector)) - ImpendingStagingPitch).
			local tDiff is time:seconds - ImpendingStagingTime.
			if tDiff < 3 {
				if (90 - vectorangle(ship:up:forevector,Ship:srfprograde:forevector)) > ImpendingStagingPitch {
					set trajectorypitch to ImpendingStagingPitch + ((pDiff*tDiff)/3).
				} else {
					set trajectorypitch to ImpendingStagingPitch - ((pDiff*tDiff)/3).
				}
			} else {
				set trajectorypitch to (90 - vectorangle(ship:up:forevector,Ship:srfprograde:forevector)).
			}
		} 
		If staginginprogress or time:seconds < stagingEndTime+3 and time:seconds > stagingEndTime { 
			set trajectorypitch to (90 - vectorangle(ship:up:forevector,Ship:srfprograde:forevector)).
			set ImpendingStagingTime to 0.
		}
		
		//Ascent TWR control for S1
		If currentstagenum = 1 {
			//Throttle engines so that TWR will not go above maxAscentTWR
			If twr() > maxAscentTWR+0.01 and not ImpendingStaging {
				scrollprint("Maintaining TWR",true).
				lock throttle to twrthrottle(maxAscentTWR).
			}
		}
		
		//Ascent TWR control for S2
		If currentstagenum > 1 and staginginprogress = false {
			//Limits upper stage to maxAscentTWR
			If twr() > maxAscentTWR+0.01 {
				scrollprint("Maintaining TWR",true).
				lock throttle to twrthrottle(maxAscentTWR).
			}
			
			//Checks if it has been 5 seconds since staging and time to apoapsis is above 120 seconds and second stage has boosted eta:apoapsis by 30 seconds since sep before gradually throttling to TWR set by UpperAscentTWR			
			If eta:apoapsis < eta:periapsis and Eta:apoapsis > stagingApoapsisETA and throttleCheck = false and (Time:seconds - stagingEndTime) >= 15 {
				set ApoEtacheck to true.
				if TWR() > UpperAscentTWR {
					set throttleCheck to true.
					set throttletime to Time:seconds.
					set currentthrottle to throttle.
					scrollprint("Throttling Down",true).
				}
			}
			If ApoEtacheck = true {
				If TWR() > UpperAscentTWR+0.01 and throttleCheck = true {
					lock throttle to max(TWRthrottle(UpperAscentTWR),((TWRthrottle(UpperAscentTWR) - currentthrottle)*((Time:seconds-throttletime)/5)+currentthrottle)).
				}
				//Throttle down near target apoapsis
				if orbitData >= targetapoapsis*0.95 and Eta:apoapsis > 30 {
					if approachingApo = false {
						set currentThrottle2 to throttle.
						set approachingApo to true.
					} else {
						lock throttle to max(TWRthrottle(0.2),currentThrottle2*((targetapoapsis-orbitData)/(targetapoapsis*0.05))).
					}
				} else if Eta:apoapsis < 75 {	//If time to apoapsis drops below 75 seconds after engines have throttled down, this will throttle them back up
					set ApoEtacheck to false.
					lock throttle to TWRthrottle(maxAscentTWR).
				}
			}
		}
		
		//End of ascent detection
		if not staginginprogress {
			if eta:apoapsis < eta:periapsis {
				if orbitData >= (targetapoapsis-50) {
					set ascentComplete to true.
				}
			} else {
				if ship:periapsis >= atmAlt {
					if ship:apoapsis >= (targetapoapsis-50) {
						set ascentComplete to true.
					}
					if ship:apoapsis >= targetapoapsis+(targetapoapsis*0.05) {
						set threeBurn to true.
						set LEO to true.
					}
				}
			}
			if LEO = true {		//Apoapsis is getting too large. Vehicle has enough dV to stop burn, burn at apoapsis to raise periapsis and then circularise at periapsis with a retrograde burn.
				if ship:apoapsis >= 1.75*targetapoapsis and eta:apoapsis > 480 and eta:apoapsis < eta:periapsis {
					if ship:altitude > body:atm:height and BurnApoapsis_TargetPeriapsis(targetperiapsis)+circulariseDV_TargetPeriapsis(targetapoapsis,targetperiapsis) < StageDV() {
						set ascentComplete to true.
						set threeBurn to true.
					}
				}
			}
		}
		
		//Insufficient Dv detection 
		if ship:apoapsis > body:atm:height*1.05 and currentstagenum = 2 and (Time:seconds - stagingEndTime) >= 15 {
			if LEO = false {
				//Cuts the burn short and will circularise at current apoapsis.
				if circulariseDV_Apoapsis() >= (StageDV()*0.95) {
					set insufficientDV to true.
				}
			} else {
				//Current periapsis is above atmosphere (we are in orbit) -> Cuts the burn short and will circularise at current periapsis.
				if ship:periapsis > atmAlt and circulariseDV_Periapsis()>=(StageDV()*0.95) {
					set insufficientDV to true.
				}
				//Periapsis is in atmosphere and if we continue to burn we may not have enough dv left to burn at apo to bring peri outside atmosphere and achieve minimum orbit
				if ship:periapsis < atmAlt and BurnApoapsis_TargetPeriapsis(atmAlt) >= (StageDV()*0.95) {
					set insufficientDV to true.
					set threeBurn to true.
				}
			}
		}
		
		//End of ascent actions
		if ascentComplete or insufficientDV {
			scrollprint("Cut-Off ",true).
			if ascentComplete {
				scrollprint("          Parking Orbit Confirmed",false).
			} else if insufficientDV {
				scrollprint("          Insufficient dV detected",false).
			}
			scrollprint("          Entering Coast Phase",false).
			lock throttle to 0.
			set ascentCompleteTime to time:seconds.
			set runmode to 3.
		}
	}

/////////////////////////////////////////////////////////////////////////
////////////////////////////ORBITAL ADJUSTMENT///////////////////////////
/////////////////////////////////////////////////////////////////////////
	
	If runmode = 3 and ship:availablethrust > 0.1 {		//Manuever Node creation for circularisation burn	
		if hasnode = false {
			if LEO = true {
				if threeBurn = true {
					if eta:apoapsis < eta:periapsis {
						set cnode to node(time:seconds + eta:apoapsis, 0, 0, BurnApoapsis_TargetPeriapsis(targetperiapsis)).
					} else {
						set cnode to node(time:seconds + eta:periapsis, 0, 0, BurnPeriapsis_TargetApoapsis(targetapoapsis)).
					}
				} else {
					//If apoapsis is closer to target
					if abs(ship:apoapsis-targetapoapsis) < (targetperiapsis-ship:periapsis) {
						set cnode to node(time:seconds + eta:apoapsis, 0, 0, circulariseDV_Apoapsis()).
					//If periapsis is closer to target
					} else if abs(ship:apoapsis-targetapoapsis) > (targetperiapsis-ship:periapsis) {
						set cnode to node(time:seconds + eta:periapsis, 0, 0, circulariseDV_Periapsis()).
					}
				}
			} else {
				set cnode to node(time:seconds + eta:apoapsis, 0, 0, circulariseDV_Apoapsis()).		
			}
			add cnode.
			set runmode to 4.
		} else {
			remove nextnode.
		}
	}

	If runmode = 4 {	//Post-ascent staging 
		set burnStartTime to time:seconds + cnode:eta - nodeBurnStart(cnode).
		set burnStarted to false.
		set burnDeltaV to cnode:deltav.
		if time:seconds < burnStartTime {
			lock steering to Ship:prograde:forevector.
			set runmode to 5.
		} else {
			rcs on.
			set runmode to 6.
		}
	}
	
	If runmode = 5 {	//Coast
		if time:seconds >= (burnStartTime - 45) {		//Will take the vehicle out of warp and prep for burn
			SET WARP TO 0.
			scrollprint("Preparing for Burn",true).
			rcs on.
			//dV check in case boil-off losses could result in incomplete burn
			if StageDV() < cnode:deltav:mag {
				set cnode:prograde to stageDV()*0.99.
				set burnStartTime to time:seconds + cnode:eta - nodeBurnStart(cnode).
				set burnDeltaV to cnode:deltav.
			} else {
				set runmode to 6.
			}
		}
	}
	
	if runmode = 6 {	//Circularisation burn
		lock steering to cnode:burnvector.
		if vang(steering,ship:facing:vector) > 5 and time:seconds >= burnStartTime-5 and burnStarted = false { 
			if throttle = 0 {
				lock throttle to twrthrottle(0.1).
				scrollprint("Correcting attitude with Thrust gimbal",false).
			}
		}
		if time:seconds >= burnStartTime and burnStarted = false and ship:availablethrust > 0.1 {
			set burnStarted to true.
			lock throttle to 1.
			scrollprint("Ignition",true).
		}

		//Handles throttle and burn end
		if burnStarted = true {
			lock throttle to min(cnode:deltav:mag/(ship:availablethrust/ship:mass),1).		//This will throttle the engine down when there is less than 1 second remaining in the burn
			if cnode:deltav:mag < 0.1 or vdot(burnDeltaV,cnode:deltav) < 0.1 or vang(ship:facing:vector,cnode:burnvector) > 5 {
				lock throttle to 0.
				scrollprint("Cut-Off",true).
				set runmode to 7.
			}
		}
	}

	If runmode = 7 {	//Triggers program end
		lock steering to Ship:prograde:forevector.
		if threeBurn = true {
			set runmode to 3.
			set threeBurn to false.
			remove cnode.
		} else {
			scrollprint("          Orbit Cicularised",false).	
			set launchcomplete to true.
		}
	}

/////////////////////////////////////////////////////////////////////////
//////////////////////////////FLIGHT EVENTS//////////////////////////////
/////////////////////////////////////////////////////////////////////////

	//Fairing separation
	If runmode = 2 and PayloadProtection = true {	
		//Jettisons fairing/LES when the altitude pressure becomes insignificant and first stage has been jettisoned
		If Body:atm:altitudepressure(ship:altitude) < 0.00002 and currentstagenum > 1 {
			set numparts to Ship:parts:length - Ship:partsingroup("AG7"):length.
			Ag7 on. 
			scrollprint("Fairings Jettisoned",true).
			set PayloadProtection to false.
		}
	}

	//Staging logic
	//RTLS Logic
	if runmode = 2 and SHIP:AIRSPEED > 1600 and stagingComplete = false and RTLS = true {
		SET WARP TO 0.
		set ImpendingStaging to true.
		if ImpendingStagingTime = 0 {
			set ImpendingStagingTime to time:seconds.
			set ImpendingStagingPitch to (90 - vectorangle(ship:up:forevector,ship:facing:forevector)).
		}
	}
	if runmode = 2 and SHIP:AIRSPEED > 1800 and stagingComplete = false and RTLS = true {
		lock throttle to 0.
		set staginginprogress to true.
		set ImpendingStaging to false.
		set stagingStartTime to Time:seconds+0.5.
		set stagingComplete to false.
		scrollprint("Cut-Off",true).
		wait 1.
		AG9 on. //Stage Sep
		set numparts to Ship:parts:length.
		set stagingStartTime to Time:seconds.
		set stagingComplete to true.
		set currentstagenum to currentstagenum+1.
		scrollprint("Stage "+currentstagenum+" separation",true).
		// This accomodates upper stage engines that 'deploy'
		If Ship:availablethrust < 0.01 and stagingComplete = true {
			set stagingStartTime to Time:seconds+0.01.
		} else If Ship:availablethrust >= 0.01 {
			Activeenginelist().
			set staginginprogress to false.
			set stagingEndTime to Time:seconds.
			set stagingApoapsisETA to eta:apoapsis.
			rcs off.
			PrimaryFuel(). PrimaryFuelMass(). FuelTankUpper(ResourceOne).
			set stagingStartTime to Time:seconds+100000.
			if runmode = 2 {
				scrollprint("Stage "+currentstagenum+" Ignition",true).
				lock throttle to min(TWRthrottle(maxAscentTWR),(TWRthrottle(maxAscentTWR)*(Time:seconds-stagingEndTime)/3)).
				lock steering to heading(launchazimuth,trajectorypitch,0).
			} else {
				lock throttle to 0.
			}
		}
	}
	//DSL Logic
	if runmode = 2 and lngoff <= 1.5 and stagingComplete = false and RTLS = false {
		SET WARP TO 0.  //Speed up flight profile
		set ImpendingStaging to true.
		if ImpendingStagingTime = 0 {
			set ImpendingStagingTime to time:seconds.
			set ImpendingStagingPitch to (90 - vectorangle(ship:up:forevector,ship:facing:forevector)).
		}
	}
	if runmode = 2 and lngoff <= .92 and stagingComplete = false and RTLS = false {
		lock throttle to 0.
		set staginginprogress to true.
		set ImpendingStaging to false.
		set stagingStartTime to Time:seconds+0.5.
		set stagingComplete to false.
		scrollprint("Cut-Off",true).
		wait 1.
		AG9 on. //Stage Sep
		set numparts to Ship:parts:length.
		set stagingStartTime to Time:seconds.
		set stagingComplete to true.
		set currentstagenum to currentstagenum+1.
		scrollprint("Stage "+currentstagenum+" separation",true).
		// This accomodates upper stage engines that 'deploy'
		If Ship:availablethrust < 0.01 and stagingComplete = true {
			set stagingStartTime to Time:seconds+0.01.
		} else If Ship:availablethrust >= 0.01 {
			Activeenginelist().
			set staginginprogress to false.
			set stagingEndTime to Time:seconds.
			set stagingApoapsisETA to eta:apoapsis.
			rcs off.
			PrimaryFuel(). PrimaryFuelMass(). FuelTankUpper(ResourceOne).
			set stagingStartTime to Time:seconds+100000.
			if runmode = 2 {
				scrollprint("Stage "+currentstagenum+" Ignition",true).
				lock throttle to min(TWRthrottle(maxAscentTWR),(TWRthrottle(maxAscentTWR)*(Time:seconds-stagingEndTime)/3)).
				lock steering to heading(launchazimuth,trajectorypitch,0).
				unlock lngoff.
				unlock latoff.
				unlock boostbackv.
			} else {
				lock throttle to 0.
			}
		}
	}

/////////////////////////////////////////////////////////////////////////
//////////////////////////////////ABORT//////////////////////////////////
/////////////////////////////////////////////////////////////////////////
	
	//Continuous abort detection logic
	If runmode > 1 {
		//Angle to desired steering > 25 deg during atmospheric ascent
		If runmode < 3 and Vang(Ship:facing:vector, steering:vector) > 25 and missiontime > 5 {
			set runmode to -13.
			scrollprint("Loss of Ship Control",true).
		}
		//Abort if number of parts less than expected
		If Ship:parts:length <= (numparts-1) and Stage:ready {
			set runmode to -13.
			scrollprint("Ship breaking apart",true).
		}
		//Abort if falling back toward surface
		If runmode = 2 and ship:altitude < atmAlt and verticalspeed < -1.0 {
			set runmode to -13.
			scrollprint("Terminal Thrust",true).
		}
		//Abort due to insufficient electric charge
		If Resourcecheck("ElectricCharge",0.01) = false {
			set runmode to -13.
			scrollprint("Insufficient Internal Power",true).
		}
	}
	
	If runmode = -13 {	//Master Abort
		for e in aelist {
			e:shutdown.
		}
		set Ship:control:neutralize to true. 
		scrollprint("Launch Aborted",false).
		set launchcomplete to true.
		break.
	}
wait 0.
}

// End of the program
unlock all. 
sas on. 
rcs off.
if hasnode { remove cnode. }
scrollprint("Flight Software Terminated",false).
Print "                                              " at (0,0).
SHUTDOWN. //shutdown flight computer