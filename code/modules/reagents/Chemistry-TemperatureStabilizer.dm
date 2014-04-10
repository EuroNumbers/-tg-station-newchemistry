#DEFINE HEATINGPOWER 400  // biggest delta T between surrounding and the heating object when it's on
#DEFINE ATMOSADJUSTPOWER 20 // delta T per tick when an open-topped stabilizer is off

// WARNING: THIS CODE MIGHT OR MIGHT NOT WORK. I HAVE NO IDEA. IT WAS NEVER COMPILED AND WAS NEVER TESTED DUE TO LACK OF TIME.
// SERIOUS SANITANTION IS NEEDED AS WELL AS SOME OPTIMIZATIONS
// MAKE SURE THE ATMOSPHERICS CODE DO NOT AND I REPEAT DO NOT CALL TEMPERATURE_EXPOSURE ON THE CONTAINERS HELD BY THESE
// Fuck get_turf

obj/machinery/chemicaltemperaturestabilizer
	name = "Temperature stabilizer."
	desc = "A flat, self-heating device designed for stabilizing chemical temperature."
	icon = 'icons/obj/science.dmi'
	icon_state = "hotplate on"
	use_power = 1
	idle_power_usage = 10
	var/obj/item/weapon/reagent_containers/held_container
	var/on = 0 						// Is it on
	var/delta_time = 5				// Time between temperature increases
	var/delta_Temp_increase = 10	// Change of temperature during delta t (Heating coil efficency)
	var/delta_Temp_decrease = 10	// Change of temperature during delta t (Freezer circulation efficency)
	var/currenttemperature = T20C   // Temperature inside of the stabilizer
	var/settemperature  = T20C+100	// Temperature to achieve
	var/mintemperature  = T0C		// Minimal temperature you can set
	var/maxtemperature  = T0C+100	// Maximum temperature you can set
	var/heater = 1					// Does it only heat
	var/cooler = 1					// Does it only cool
	var/open = 0					// Insulated from the outside

obj/machinery/chemicaltemperaturestabilizer/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if(istype(W, /obj/item/weapon/reagent_containers))
		if(held_container)
			user << "\red You must remove the [held_container] first."
		else
			user.drop_item(src)
			held_container = W
			held_container.loc = src
			user << "\blue You put the [held_container] onto the [src]."
			var/image/I = image("icon"=W, "layer"=FLOAT_LAYER)
			underlays += I
	else
		user << "\red You can't put the [W] onto the [src]."

obj/machinery/chemicaltemperaturestabilizer/attack_hand(mob/user as mob)
	if(held_container)
		underlays = null
		user << "\blue You remove the [held_container] from the [src]."
		held_container.loc = src.loc
		held_container.attack_hand(user)
		held_container = null
	else
		user << "\red There is nothing on the [src]."

obj/machinery/chemicaltemperaturestabilizer/temperaturenormalization() // Temperature normalization - when the thing is off, temperature should adjust to turf's temperature.

	var/turf/simulated/currentturf = get_turf(my_atom)
	var/datum/gas_mixture/enviroment = currentturf.return_air()	// I HATE THE FACT I HAVE TO DO THIS
	
	if currenttemperature > enviroment.temperature												// Stabilize temperature down
		currenttemperature = max(currenttemperature-ATMOSADJUSTPOWER, enviroment.temperature)   
		return
	
	if currenttemperature < enviroment.temperature												// Stabilize temperature up
		currenttemperature = min(currenttemperature+ATMOSADJUSTPOWER, enviroment.temperature)
		return


obj/machinery/chemicaltemperaturestabilizer/temperatureadjustment()    // Temperature adjustment - heating and cooling function. Uses get_turf() if the thing is open.

	if(open)														  // If it's open-topped make sure it has enough power to heat it up. If it doesn't, use ATMOS MAGICS
		var/turf/simulated/currentturf = get_turf(my_atom)
		var/datum/gas_mixture/enviroment = currentturf.return_air()
		if (abs(currenttemperature-enviroment.temperature) > HEATINGPOWER)  // Check HEATING POWER both ways. I made it a define cause it will be adjustable to put more/less strain on atmos and more/less realism. Best to have it around 400-500 for best effects.
		temperaturenormalization()											// Clever eh? Possibly have the temperature pass to normalization as a parametr to limit get_turfs
		return
		
	if((currenttemperature < settemperature) && (heater))						// Heaters heat stuff
		currenttemperature =+ delta_Temp_increase
		currenttemperature = min(currenttemperature, settemperature)
		return
		
	if((currenttemperature > settemperature) && (cooler))						// Coolers cool stuff
		currenttemperature =- delta_Temp_decrease
		currenttemperature = max(currenttemperature, settemperature)
		return
		

obj/machinery/chemicaltemperaturestabilizer/process()
	
	if(stat & (NOPOWER|BROKEN))	return //If unpowered or broken, don't do a thing
	
	if((on == 1) && (currenttemperature == settemperature) && (held_container))		// If currenttemp = settemp, then don't bother doing adjustments
		spawn(tempchangedelay)
		held_container.reagents.handle_reactions()
		return
	
	if((on == 1) && (currenttemperature <> settemperature) && (held_container))		// Adjust the temperatures for open and closed containers as long as they run
		spawn(tempchangedelay)
		temperatureadjustment()
		held_container.reagents.handle_reactions()
		return
	
	if((on == 0) && (held_container) && (open))										// For open-topped make them cool off
		spawn(tempchangedelay)
		temperaturenormalization()	
		held_container.reagents.handle_reactions()
		return
		


obj/machinery/chemicaltemperaturestabilizer/hotplate
	name = "Hotplate."
	desc = "Chemists' best friend... right after a bottle of vodka and a bed he/she cries on every night." // I hate my life and I wish to die - Numbers
	delta_Temp_increase = 20	
	settemperature  = T20C
	mintemperature  = T20C
	maxtemperature  = T0C+400	
	heater = 1
	cooler = 0
	open = 1	


obj/machinery/chemicaltemperaturestabilizer/oven
	name = "Chemical Oven."
	desc = "Closed off oven for heating chemicals up."
	delta_Temp_increase = 15
	delta_Temp_decrease = 5
	settemperature  = T20C
	mintemperature  = T20C
	maxtemperature  = T0C+400


obj/machinery/chemicaltemperaturestabilizer/freezer
	name = "Freezer."
	desc = "A portable freezer for freezing chemicals and doing reactions in low temperatures."
	delta_Temp_increase = 5
	delta_Temp_decrease = 15
	settemperature  = T0C
	mintemperature  = T0C-60
	maxtemperature  = T0C+5

obj/machinery/chemicaltemperaturestabilizer/thermostat
	name = "Thermostat."
	desc = "Sealed container that uses cooling and heating circuits to stabilize temperature ona certain level."
	delta_Temp_increase = 10
	delta_Temp_decrease = 5
	settemperature  = T20C
	mintemperature  = T0C-10
	maxtemperature  = T0C+60

