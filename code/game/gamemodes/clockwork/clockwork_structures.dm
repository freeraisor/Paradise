/obj/structure/clockwork
	density = 1
	anchored = TRUE
	layer = BELOW_OBJ_LAYER
	icon = 'icons/obj/clockwork.dmi'

/obj/structure/clockwork/beacon
	name = "herald's beacon"
	desc = "An imposing spire formed of brass. It somewhat pulsates."
	icon_state = "beacon"

/obj/structure/clockwork/altar
	name = "credence"
	desc = "A strange brass platform with spinning cogs inside. It demands somethinge in exchange for goods..."
	icon_state = "altar"
	density = 0

/obj/structure/clockwork/functional
	max_integrity = 100
	var/cooldowntime = 0
	var/death_message = "<span class='danger'>The structure falls apart.</span>"
	var/death_sound = 'sound/effects/forge_destroy.ogg'
	var/hidden = FALSE

/obj/structure/clockwork/functional/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/clockwork/clockslab) && isclocker(user))
		if(I.enchant_type == HIDE_SPELL)
			toggle_hide()
			to_chat(user, "<span class='notice'>You [hidden ? null : "un"]disguise [src].</span>")
			playsound(user, 'sound/magic/cult_spell.ogg', 25, TRUE)
			I.deplete_spell()
			return TRUE
		if(hidden)
			to_chat(user, "<span class='warning'>You have to clear the view of this structure in order to manipulate with it!</span>")
			return TRUE
		anchored = !anchored
		to_chat(user, "<span class='notice'>You [anchored ? "":"un"]secure [src] [anchored ? "to":"from"] the floor.</span>")
		if(!anchored)
			icon_state = "[initial(icon_state)]-off"
		else
			icon_state = "[initial(icon_state)]"
		update_icon()
		return TRUE
	return ..()

/obj/structure/clockwork/functional/obj_destruction()
	visible_message(death_message)
	playsound(src, death_sound, 50, TRUE)
	. = ..()

/obj/structure/clockwork/functional/examine(mob/user)
	. = ..()
	if(hidden && isclocker(user))
		. += "<span class='notice'>It's a disguised [initial(name)]!</span>"

// returns TRUE if hidden, if unhidden FALSE
/obj/structure/clockwork/functional/proc/toggle_hide()
	hidden = !hidden
	if(!hidden)
		name = initial(name)
		desc = initial(desc)
		icon = initial(icon)
		if(!anchored)
			icon_state = "[initial(icon_state)]-off"
		else
			icon_state = "[initial(icon_state)]"
		return FALSE
	switch(rand(1,5))
		if(1)
			name = "rack"
			desc = "Different from the Middle Ages version. <BR><span class='notice'>It's held together by a couple of <b>bolts</b>.</span>"
			icon = 'icons/obj/objects.dmi'
			icon_state = "rack"
		if(2)
			name = "wooden table"
			desc = "Do not apply fire to this. Rumour says it burns easily. <BR><span class='notice'>The top is <b>screwed</b> on, but the main <b>bolts</b> are also visible.</span>"
			icon = 'icons/obj/smooth_structures/wood_table.dmi'
			icon_state = "wood_table"
		if(3)
			name = "personal closet"
			desc = "It's a secure locker for personnel. The first card swiped gains control."
			icon = 'icons/obj/closet.dmi'
			icon_state = "secureoff"
		if(4)
			name = "girder"
			desc = "<span class='notice'>The bolts are <b>lodged</b> in place.</span>"
			icon = 'icons/obj/structures.dmi'
			icon_state = "girder"
		if(5)
			name = "bookcase"
			desc = null
			icon = 'icons/obj/library.dmi'
			icon_state = "book-4"
	return TRUE

/obj/structure/clockwork/functional/beacon
	name = "herald's beacon"
	desc = "An imposing spire formed of brass. It somewhat pulsates."
	icon_state = "beacon"
	max_integrity = 750 // A very important one
	death_message = "<span class='danger'>The beacon crumbles and falls in parts to the ground relaesing it's power!</span>"
	death_sound = 'sound/effects/creepyshriek.ogg'
	var/heal_delay = 60
	var/last_heal = 0
	var/area/areabeacon
	var/areastring = null
	color = "#FFFFFF"

/obj/structure/clockwork/functional/beacon/Initialize(mapload)
	. = ..()
	areabeacon = get_area(src)
	GLOB.clockwork_beacons += src
	START_PROCESSING(SSobj, src)
	var/area/A = get_area(src)
	//if area isn't specified use current
	if(isarea(A))
		areabeacon = A
	SSticker.mode.clocker_objs.beacon_check()

/obj/structure/clockwork/functional/beacon/process()
	adjust_clockwork_power(CLOCK_POWER_BEACON)

	if(last_heal <= world.time)
		last_heal = world.time + heal_delay
		for(var/mob/living/L in range(5, src))
			if(!isclocker(L))
				continue
			if(!(L.health < L.maxHealth))
				continue
			new /obj/effect/temp_visual/heal(get_turf(L), "#960000")

			if(ishuman(L))
				L.heal_overall_damage(10, 10, TRUE)

			else if(isanimal(L))
				var/mob/living/simple_animal/M = L
				if(M.health < M.maxHealth)
					M.adjustHealth(-8)

			if(ishuman(L) && L.blood_volume < BLOOD_VOLUME_NORMAL)
				L.blood_volume += 1

/obj/structure/clockwork/functional/beacon/Destroy()
	GLOB.clockwork_beacons -= src
	STOP_PROCESSING(SSobj, src)
	for(var/datum/mind/M in SSticker.mode.clockwork_cult)
		to_chat(M.current, "<span class='danger'>You get the feeling that one of the beacons have been destroyed! The source comes from [areabeacon.name]</span>")
	return ..()

/obj/structure/clockwork/functional/beacon/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/clockwork/clockslab) && isclocker(user))
		to_chat(user, "<span class='danger'>You try to unsecure [src], but it's secures himself back tightly!</span>")
		return TRUE
	return ..()

/obj/structure/clockwork/functional/altar
	name = "credence"
	desc = "A strange brass platform with spinning cogs inside. It demands somethinge in exchange for goods..."
	icon_state = "altar"
	density = 0
	death_message = "<span class='danger'>The alter breaks in pieces as it dusts into nothing!</span>"
	var/locname = null
	var/obj/effect/temp_visual/ratvar/altar_convert/glow

	var/mob/living/carbon/human/converting = null // Who is getting converted
	var/mob/living/has_clocker = null // A clocker who checks the converting

	var/first_stage = FALSE // Did convert started?
	var/second_stage = FALSE // Did we started to gib someone?
	var/third_stage = FALSE // Did we already made a cube?
	var/convert_timer = 0

/obj/structure/clockwork/functional/altar/Initialize(mapload)
	. = ..()
	var/area/A = get_area(src)
	locname = initial(A.name)
	GLOB.clockwork_altars += src
	START_PROCESSING(SSprocessing, src)

/obj/structure/clockwork/functional/altar/Destroy()
	GLOB.clockwork_altars -= src
	if(converting)
		stop_convert()
	STOP_PROCESSING(SSprocessing, src)
	return ..()

/obj/structure/clockwork/functional/altar/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/clockwork/clockslab) && isclocker(user))
		if(I.enchant_type == HIDE_SPELL)
			if(!toggle_hide())
				STOP_PROCESSING(SSprocessing, src)
			else
				if(anchored)
					START_PROCESSING(SSprocessing, src)
			to_chat(user, "<span class='notice'>You [hidden ? null : "un"]disguise [src].</span>")
			playsound(user, 'sound/magic/cult_spell.ogg', 25, TRUE)
			I.deplete_spell()
			return TRUE
		if(hidden)
			to_chat(user, "<span class='warning'>You have to clear the view of this structure in order to manipulate with it!</span>")
			return TRUE
		anchored = !anchored
		to_chat(user, "<span class='notice'>You [anchored ? "":"un"]secure [src] [anchored ? "to":"from"] the floor.</span>")
		if(!anchored)
			icon_state = "[initial(icon_state)]-off"
			STOP_PROCESSING(SSprocessing, src)
		else
			icon_state = "[initial(icon_state)]"
			START_PROCESSING(SSprocessing, src)
		update_icon()
		return TRUE
	return ..()

/obj/structure/clockwork/functional/altar/toggle_hide()
	hidden = !hidden
	if(!hidden)
		name = initial(name)
		desc = initial(desc)
		icon = initial(icon)
		if(!anchored)
			icon_state = "[initial(icon_state)]-off"
		else
			icon_state = "[initial(icon_state)]"
		return FALSE
	switch(rand(1,5))
		if(1, 2, 3)
			name = "potted plant"
			desc = null
			icon = 'icons/obj/flora/plants.dmi'
			icon_state = "plant-[rand(1,36)]"
		if(4)
			name = "chair"
			desc = "You sit in this. Either by will or force."
			icon = 'icons/obj/chairs.dmi'
			icon_state = "chair"
		if(5)
			name = "stool"
			desc = "Apply butt."
			icon = 'icons/obj/chairs.dmi'
			icon_state = "stool"

/obj/structure/clockwork/functional/altar/Crossed(atom/movable/AM, oldloc)
	. = ..()
	if(!converting && ishuman(AM) && !isclocker(AM) && !hidden && anchored)
		converting = AM
		first_stage_check(converting)


/obj/structure/clockwork/functional/altar/Uncrossed(atom/movable/AM)
	. = ..()
	if(AM == converting)
		if(first_stage)
			stop_convert()
		converting = null
		convert_timer = 1

/obj/structure/clockwork/functional/altar/process()
	if(!converting)
		var/list/mob/living/carbon/human/bodies = list()
		for(var/mob/living/carbon/human/H in range(0, src))
			if(isclocker(H))
				continue
			if(!H.mind)
				continue
			bodies += H
		if(bodies.len)
			converting = pick(bodies)
		convert_timer = 0
	else if(!has_clocker)
		for(var/mob/living/M in range(1, src))
			if(isclocker(M) && M.stat == CONSCIOUS)
				has_clocker = M
				break
	else
		convert_timer++
		has_clocker = null
		for(var/mob/living/M in range(1, src))
			if(isclocker(M) && M.stat == CONSCIOUS)
				has_clocker = M
				break
		if(!has_clocker)
			stop_convert()
		if(!anchored || hidden)
			stop_convert()
		if(isclocker(converting))
			stop_convert(TRUE)
		switch(convert_timer)
			if(-INFINITY to 8)
				if(!first_stage)
					first_stage_check(converting)
			if(8 to 16)
				if(!second_stage)
					second_stage_check(converting)
				else
					converting.adjustBruteLoss(5)
					converting.adjustFireLoss(5)
			if(16 to INFINITY)
				if(!third_stage)
					convert_to_cube(converting)
				stop_convert() // one time the third stage activates

/obj/structure/clockwork/functional/altar/proc/first_stage_check(var/mob/living/carbon/human/target)
	first_stage = TRUE
	target.visible_message("<span class='warning'>[src] begins to glow a piercing amber!</span>", "<span class='clock'>You feel something start to invade your mind...</span>")
	glow = new (get_turf(src))
	animate(glow, alpha = 255, time = 8 SECONDS)
	icon_state = "[initial(icon_state)]-fast"
	convert_timer = 0

/obj/structure/clockwork/functional/altar/proc/second_stage_check(var/mob/living/carbon/human/target)
	second_stage = TRUE
	if(!is_convertable_to_clocker(target.mind) || target.stat == DEAD) // mindshield or holy or mindless monkey. or dead guy
		target.visible_message("<span class='warning'>[src] in glowing manner starts corrupting [target]!</span>", \
		"<span class='danger'>You feel as your body starts to corrupt by [src] underneath!</span>")
		target.Weaken(10)
	else // just a living non-clocker civil
		to_chat(target, "<span class='clocklarge'><b>\"You belong to me now.\"</b></span>")
		target.heal_overall_damage(50, 50, TRUE)
		if(isgolem(target))
			target.mind.wipe_memory()
			target.set_species(/datum/species/golem/clockwork)
		if(SSticker.mode.add_clocker(target.mind))
			target.create_log(CONVERSION_LOG, "[target] been converted into clockwork cult by altar.")
		target.Weaken(5) //Accept new power... and new information
		target.EyeBlind(5)
		stop_convert(TRUE)

/obj/structure/clockwork/functional/altar/proc/convert_to_cube(var/mob/living/carbon/human/target)
	third_stage = TRUE
	var/obj/item/mmi/robotic_brain/clockwork/cube = new (get_turf(src))
	cube.try_to_transfer(target)
	adjust_clockwork_power(CLOCK_POWER_SACRIFICE)

/obj/structure/clockwork/functional/altar/proc/stop_convert(var/silent = FALSE)
	QDEL_NULL(glow)
	first_stage = FALSE
	second_stage = FALSE
	third_stage = FALSE
	convert_timer = 0
	converting = null
	if(anchored)
		icon_state = "[initial(icon_state)]"
	else
		icon_state = "[initial(icon_state)]-off"
	if(!silent)
		visible_message("<span class='warning'>[src] slowly stops glowing!</span>")

/obj/structure/clockwork/functional/altar/attackby(obj/item/I, mob/user, params)
	. = ..()
	if(istype(I, /obj/item/clockwork/shard))
		if(!ishuman(user))
			to_chat(user, "span class='warning'>You are too weak to push the shard inside!</span>")
			return
		var/area/A = get_area(src)
		if(!anchored)
			to_chat(user, "<span class='warning'>It has to be anchored before you can start!</span>")
		if(!double_check(user, A))
			return
		GLOB.command_announcement.Announce("A high anomalous power has been detected in [A.map_name], the origin of the power indicates an attempt to summon eldtrich god named Ratvar. Disrupt the ritual at all costs, before the station is destroyed! Space law and SOP are suspended. The entire crew must kill cultists on sight.", "Central Command Higher Dimensional Affairs", 'sound/AI/spanomalies.ogg')
		visible_message("<span class='biggerdanger'>[user] ominously presses [I] into [src] as the mechanism inside starts to shine!</span>")
		user.unEquip(I)
		qdel(I)
		begin_the_ritual()

/obj/structure/clockwork/functional/altar/proc/double_check(mob/living/user, area/A)
	var/datum/game_mode/gamemode = SSticker.mode

	if(GLOB.ark_of_the_clockwork_justiciar)
		to_chat(user, "<span class='clockitalic'>There is already Gateway somewhere!</span>")
		return FALSE

	if(gamemode.clocker_objs.clock_status < RATVAR_NEEDS_SUMMONING)
		to_chat(user, "<span class='clockitalic'><b>Ratvar</b> is not ready to be summoned yet!</span>")
		return FALSE
	if(gamemode.clocker_objs.clock_status == RATVAR_HAS_RISEN)
		to_chat(user, "<span class='clocklarge'>\"My fellow. There is no need for it anymore.\"</span>")
		return FALSE

	var/list/summon_areas = gamemode.clocker_objs.obj_summon.ritual_spots
	if(!(A in summon_areas))
		to_chat(user, "<span class='cultlarge'>Ratvar can only be summoned where the veil is weak - in [english_list(summon_areas)]!</span>")
		return FALSE
	var/confirm_final = alert(user, "This is the FINAL step to summon, the crew will be alerted to your presence AND your location!",
	"The power comes...", "Let Ratvar shine ones more!", "No")
	if(user)
		if(confirm_final == "No" || confirm_final == null)
			to_chat(user, "<span class='clockitalic'><b>You decide to prepare further before pincing the shard.</b></span>")
			return FALSE
		return TRUE

/obj/structure/clockwork/functional/altar/proc/begin_the_ritual()
	visible_message("<span class='danger'>The [src] expands itself revealing into the great Ark!</span>")
	new /obj/structure/clockwork/functional/celestial_gateway(get_turf(src))
	qdel(src)
	return

/// for area.get_beacon() returns BEACON if it exists
/area/proc/get_beacon()
	for(var/thing in GLOB.clockwork_beacons)
		var/obj/structure/clockwork/functional/beacon/BEACON = thing
		if(BEACON.areabeacon == get_area(src))
			return BEACON

