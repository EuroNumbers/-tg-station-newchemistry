#define DELTATEMPKICKIN 5

/obj/item/weapon/reagent_containers
	name = "Container"
	desc = "..."
	icon = 'icons/obj/chemical.dmi'
	icon_state = null
	w_class = 1
	var/amount_per_transfer_from_this = 5
	var/possible_transfer_amounts = list(5,10,15,25,30)
	var/volume = 30
	var/oldtemp = T20C

/obj/item/weapon/reagent_containers/verb/set_APTFT() //set amount_per_transfer_from_this
	set name = "Set transfer amount"
	set category = "Object"
	set src in range(0)
	var/N = input("Amount per transfer from this:","[src]") as null|anything in possible_transfer_amounts
	if (N)
		amount_per_transfer_from_this = N

/obj/item/weapon/reagent_containers/New()
	..()
	if (!possible_transfer_amounts)
		src.verbs -= /obj/item/weapon/reagent_containers/verb/set_APTFT
	create_reagents(volume)

/obj/item/weapon/reagent_containers/attack_self(mob/user as mob)
	return

/obj/item/weapon/reagent_containers/attack(mob/M as mob, mob/user as mob, def_zone)
	return

// this prevented pills, food, and other things from being picked up by bags.
// possibly intentional, but removing it allows us to not duplicate functionality.
// -Sayu (storage conslidation)
/*
/obj/item/weapon/reagent_containers/attackby(obj/item/I as obj, mob/user as mob)
	return
*/
/obj/item/weapon/reagent_containers/afterattack(obj/target, mob/user , flag)
	return

// This is attachment for temperature reactions from atmosphere. Works with temperature_expose function that is usually triggered by fires. It needs to be 
// assigned to kick in for reagent_containers for LOWER temperatures

/obj/item/weapon/reagent_containers/temperature_expose(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	// OPTIMIZATION - Why the hell would you check for every 0.1 change. DELTATEMPKICKIN is to lower the amount of calls to handle_reactions()
	// So that in the scope of +/-DELTATEMPKICKIN change there won't be a call
	if (( oldtemp-DELTATEMPKICKIN > exposed_temperature ) || ( oldtemp+DELTATEMPKICKIN < exposed_temperature ))
	// When it kicks in, write down what was the old temperature
		oldtemp = exposed_temperature
	// WHAM!
		src.reagents.handle_reactions()

/obj/item/weapon/reagent_containers/proc/reagentlist(var/obj/item/weapon/reagent_containers/snack) //Attack logs for regents in pills
	var/data
	if(snack.reagents.reagent_list && snack.reagents.reagent_list.len) //find a reagent list if there is and check if it has entries
		for (var/datum/reagent/R in snack.reagents.reagent_list) //no reagents will be left behind
			data += "[R.id]([R.volume] units); " //Using IDs because SOME chemicals(I'm looking at you, chlorhydrate-beer) have the same names as other chemicals.
		return data
	else return "No reagents"
